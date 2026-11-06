import type { Env } from './env';
import { error } from './catalog';
import { hash, immutable, readManifest, verifyBytes, verifyStored, type Receipt } from './publication';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
  'Access-Control-Allow-Headers': 'If-None-Match',
  'Access-Control-Expose-Headers': 'ETag, Link, X-Content-SHA256, Retry-After',
};

/** Only committed, visible Pack revisions can be read; never expose arbitrary R2 keys. */
export async function download(request: Request, env: Env): Promise<Response> {
  const url = new URL(request.url);
  const match = /^\/content\/v1\/packs\/([^/]+)\/(download|revisions\/([1-9][0-9]*)\/(manifest|signature|archive\.biguesspack|objects\/[a-f0-9]{64}\.(?:webp|png|jpg)))$/.exec(url.pathname);
  if (!match) return error(404, 'not_found', 'Endpoint not found.');
  if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: cors });
  if (request.method !== 'GET' || url.search) return error(400, 'invalid_request', 'Use GET without query parameters.');
  let packId: string;
  try { packId = decodeURIComponent(match[1]); } catch { return error(400, 'invalid_request', 'Invalid Pack ID.'); }
  const latest = match[2] === 'download';
  const revision = latest ? null : Number(match[3]);
  if (!latest && !Number.isSafeInteger(revision)) return error(400, 'invalid_request', 'Invalid revision.');
  try {
    // One read obtains visibility and the exact receipt, including during a publication.
    const row = await env.DB.prepare(`SELECT p.published, p.deleted,
      t.published AS topic_published, t.deleted AS topic_deleted, r.receipt
      FROM catalog_packs p JOIN catalog_topics t ON t.id = p.topic_id
      LEFT JOIN publication_revisions r ON r.pack_id = p.id AND r.revision = COALESCE(?, p.revision)
      WHERE p.id = ?`).bind(revision, packId).first<{
        published: number; deleted: number; topic_published: number; topic_deleted: number; receipt: string | null;
      }>();
    if (!row) return error(404, 'not_found', 'Pack not found.');
    if (row.deleted || row.topic_deleted) return error(410, 'deleted', 'Content was deleted.');
    if (!row.published || !row.topic_published) return error(403, 'unavailable', 'Content is unavailable.');
    if (!row.receipt) return error(404, 'not_found', 'Revision not found.');
    const receipt = JSON.parse(row.receipt) as Receipt;
    // Verify storage before conditional responses too. Damage never becomes a successful download.
    await verifyStored(env, receipt);
    const s = receipt.statement;
    if (s.packId !== packId || (!latest && s.revision !== revision)) throw new Error('receipt_identity');
    const base = `${url.origin}/content/v1/packs/${encodeURIComponent(packId)}/revisions/${s.revision}/`;
    let bytes: Uint8Array;
    let contentType = 'application/json';
    let cacheControl = immutable;
    if (latest) {
      cacheControl = 'public, max-age=60, must-revalidate';
      bytes = new TextEncoder().encode(JSON.stringify({ protocolVersion: 1, packId, revision: s.revision,
        manifestUrl: base + 'manifest', manifestSha256: s.manifestSha256,
        archiveUrl: base + 'archive.biguesspack', archiveSha256: s.archiveSha256,
        sizeBytes: s.archiveSizeBytes, manifestSchemaVersion: 1 }));
    } else if (match[4] === 'signature') {
      bytes = new TextEncoder().encode(row.receipt);
    } else if (match[4] === 'manifest') {
      bytes = (await readManifest(env, receipt)).bytes;
    } else {
      const { manifest } = await readManifest(env, receipt);
      const image = manifest.objects.find(o => o.key === match[4]);
      if (match[4] !== 'archive.biguesspack' && !image) return error(404, 'not_found', 'Object not found in this revision.');
      const key = image ? image.key : `archives/${s.archiveSha256}.biguesspack`;
      const object = await env.CONTENT.get(key);
      if (!object) throw new Error('missing_object');
      bytes = new Uint8Array(await object.arrayBuffer());
      // Recheck bytes actually returned, even if storage changes after verifyStored.
      await verifyBytes(bytes, image?.sha256 ?? s.archiveSha256, image?.sizeBytes ?? s.archiveSizeBytes);
      contentType = image?.mediaType ?? 'application/zip';
    }
    const digest = await hash(bytes);
    const etag = `"${digest}"`;
    const headers = { ...cors, 'Content-Type': contentType, 'Cache-Control': cacheControl,
      ETag: etag, 'X-Content-SHA256': digest, Link: `<${base}signature>; rel="describedby"` };
    const tags = request.headers.get('If-None-Match')?.split(',').map(t => t.trim());
    if (tags?.some(t => t === '*' || t.replace(/^W\//, '') === etag)) return new Response(null, { status: 304, headers });
    return new Response(bytes, { headers });
  } catch {
    return error(503, 'internal_error', 'Pack storage is temporarily unavailable.');
  }
}

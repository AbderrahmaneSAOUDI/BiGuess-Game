import type { Env } from './env';
import { hash, readManifest, verifyReceipt, verifyStored, type Manifest, type Receipt } from './publication';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, If-None-Match',
  'Access-Control-Expose-Headers': 'ETag, Retry-After',
};
const validId = (v: unknown): v is string => typeof v === 'string' && v.length > 0 && !/[\s\p{Cc}\p{Cs}]/u.test(v);
const revision = (v: unknown): v is number => typeof v === 'number' && Number.isSafeInteger(v) && v > 0;
const fields = (v: unknown, keys: string[]): v is Record<string, unknown> => !!v && typeof v === 'object'
  && !Array.isArray(v) && Object.keys(v).length === keys.length && keys.every(k => Object.hasOwn(v, k));
function error(status: number, code: string, message: string, currentRevision: number | null = null): Response {
  return Response.json({ protocolVersion: 1, error: { code, message,
    requestId: crypto.randomUUID(), retryable: status === 503, currentRevision } },
  { status, headers: { ...cors, 'Cache-Control': 'no-store', ...(status === 503 ? { 'Retry-After': '5' } : {}) } });
}
async function requestBody(request: Request): Promise<unknown> {
  const reader = request.body?.getReader();
  if (!reader) throw new Error('invalid_json');
  const chunks: Uint8Array[] = []; let length = 0;
  while (true) {
    const { done, value } = await reader.read(); if (done) break;
    length += value.length;
    if (length > 65536) { await reader.cancel(); throw new Error('invalid_json'); }
    chunks.push(value);
  }
  const bytes = new Uint8Array(length); let offset = 0;
  for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.length; }
  return JSON.parse(new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(bytes));
}
interface KnownPack { packId: string; revision: number }
interface StatusRow {
  pack_id: string;
  catalog_id: string | null; published: number | null; deleted: number | null;
  revision: number | null; manifest_sha256: string | null; topic_id: string | null;
  topic_published: number | null; topic_deleted: number | null;
  head_revision: number | null; receipt: string | null;
  studio_revision: number | null; state: string | null;
  tombstone_revision: number | null; deleted_at: string | null;
}

async function revisions(request: Request, env: Env): Promise<Response> {
  if (request.method !== 'POST' || new URL(request.url).search) return error(400, 'invalid_request', 'Use POST without query parameters.');
  let payload: unknown;
  try { payload = await requestBody(request); }
  catch { return error(400, 'invalid_request', 'Send a JSON revision request of at most 64 KiB.'); }
  if (!fields(payload, ['protocolVersion', 'packs'])) return error(400, 'invalid_request', 'Invalid revision request fields.');
  if (payload.protocolVersion !== 1) return error(426, 'unsupported_protocol', 'Use content protocol version 1.');
  if (!Array.isArray(payload.packs) || payload.packs.length < 1 || payload.packs.length > 100
    || !payload.packs.every(p => fields(p, ['packId', 'revision']) && validId(p.packId) && revision(p.revision))) {
    return error(400, 'invalid_request', 'Submit 1–100 distinct Pack IDs and positive revisions.');
  }
  const known = payload.packs as KnownPack[];
  if (new Set(known.map(p => p.packId)).size !== known.length) return error(400, 'invalid_request', 'Pack IDs must be distinct.');
  try {
    // One read transaction preserves per-request consistency. Start from explicit
    // installed IDs, never the catalog, so removing a projection cannot erase a deletion.
    const rows = (await env.DB.prepare(`SELECT json_extract(k.value, '$.packId') AS pack_id,
      p.id AS catalog_id, p.published, p.deleted, p.revision, p.manifest_sha256, p.topic_id,
      t.published AS topic_published, t.deleted AS topic_deleted,
      h.revision AS head_revision, r.receipt, e.revision AS studio_revision, e.state,
      d.revision AS tombstone_revision, d.deleted_at
      FROM json_each(?) k
      LEFT JOIN catalog_packs p ON p.id = json_extract(k.value, '$.packId')
      LEFT JOIN catalog_topics t ON t.id = p.topic_id
      LEFT JOIN publication_heads h ON h.pack_id = json_extract(k.value, '$.packId')
      LEFT JOIN publication_revisions r ON r.pack_id = h.pack_id AND r.revision = h.revision
      LEFT JOIN studio_entities e ON e.resource_type = 'pack' AND e.id = json_extract(k.value, '$.packId')
      LEFT JOIN studio_tombstones d ON d.resource_type = 'pack' AND d.resource_id = json_extract(k.value, '$.packId')
        AND d.revision = (SELECT MAX(revision) FROM studio_tombstones
          WHERE resource_type = 'pack' AND resource_id = json_extract(k.value, '$.packId'))
      ORDER BY CAST(k.key AS INTEGER)`).bind(JSON.stringify(known)).all<StatusRow>()).results;
    const results: unknown[] = [];
    for (const [i, row] of rows.entries()) {
      const installed = known[i].revision;
      const lastDeletion = row.tombstone_revision;
      const current = Math.max(row.revision ?? 0, row.head_revision ?? 0, row.studio_revision ?? 0, lastDeletion ?? 0);
      if (!current) { results.push({ packId: row.pack_id, status: 'unknown' }); continue; }
      if (installed > current) return error(409, 'revision_conflict', 'Installed revision is ahead of server state.', current);
      if (lastDeletion !== null && lastDeletion > installed) {
        if (!row.deleted_at || !Number.isFinite(Date.parse(row.deleted_at)) || !row.deleted_at.endsWith('Z')) throw new Error('invalid_tombstone');
        results.push({ packId: row.pack_id, status: 'deleted', tombstone: {
          packId: row.pack_id, revision: lastDeletion, deletedAt: row.deleted_at, reason: 'administrative_deletion',
        } });
        continue;
      }
      const deleted = row.deleted === 1 || row.state === 'deleted' || row.state === 'purged';
      if (deleted && lastDeletion !== null) return error(409, 'revision_conflict', 'Deletion evidence must be newer than the installed revision.', lastDeletion);
      if (!row.catalog_id || !row.published || !row.topic_published || row.topic_deleted || deleted) {
        results.push({ packId: row.pack_id, status: 'unavailable' }); continue;
      }
      // Draft revisions are not distribution promises. Only a validated, committed
      // publication may be advertised as unchanged or as an available update.
      if (!row.receipt || row.revision !== row.head_revision) throw new Error('invalid_projection');
      const receipt = JSON.parse(row.receipt) as Receipt;
      await verifyReceipt(env, receipt);
      const s = receipt.statement;
      if (s.packId !== row.pack_id || s.topicId !== row.topic_id || s.revision !== row.revision
        || s.manifestSha256 !== row.manifest_sha256) throw new Error('invalid_projection');
      if (installed > s.revision) return error(409, 'revision_conflict', 'Installed revision is ahead of the published revision.', s.revision);
      results.push({ packId: row.pack_id, revision: s.revision,
        status: installed === s.revision ? 'unchanged' : 'updateAvailable', manifestSha256: s.manifestSha256 });
    }
    return Response.json({ protocolVersion: 1, results }, { headers: { ...cors, 'Cache-Control': 'no-store' } });
  } catch { return error(503, 'internal_error', 'Revision metadata is temporarily unavailable.'); }
}

interface DeltaRow {
  published: number; deleted: number; topic_published: number; topic_deleted: number;
  topic_id: string; base_receipt: string | null; target_receipt: string | null;
}
const sameCard = (a: Manifest['cards'][number], b: Manifest['cards'][number]) => a.id === b.id && a.packId === b.packId
  && a.name === b.name && a.imageReference === b.imageReference && a.difficulty === b.difficulty;

async function delta(request: Request, env: Env, match: RegExpExecArray): Promise<Response> {
  if (request.method !== 'GET') return error(400, 'invalid_request', 'Use GET to read a Pack delta.');
  const url = new URL(request.url);
  let packId: string;
  try { packId = decodeURIComponent(match[1]); } catch { return error(400, 'invalid_request', 'Invalid Pack ID.'); }
  if (!validId(packId)) return error(400, 'invalid_request', 'Invalid Pack ID.');
  const fromRaw = url.searchParams.get('fromRevision'); const toRaw = url.searchParams.get('toRevision');
  if ([...url.searchParams.keys()].some(k => !['fromRevision', 'toRevision'].includes(k))
    || url.searchParams.getAll('fromRevision').length !== 1 || url.searchParams.getAll('toRevision').length !== 1
    || !/^[1-9][0-9]*$/.test(fromRaw ?? '') || !/^[1-9][0-9]*$/.test(toRaw ?? '')
    || !revision(Number(fromRaw)) || !revision(Number(toRaw)) || Number(fromRaw) >= Number(toRaw)) {
    return error(400, 'invalid_request', 'Specify exact positive revisions with fromRevision less than toRevision.');
  }
  const fromRevision = Number(fromRaw); const toRevision = Number(toRaw);
  try {
    const row = await env.DB.prepare(`SELECT p.published, p.deleted, p.topic_id,
      t.published AS topic_published, t.deleted AS topic_deleted,
      a.receipt AS base_receipt, b.receipt AS target_receipt
      FROM catalog_packs p JOIN catalog_topics t ON t.id = p.topic_id
      LEFT JOIN publication_revisions a ON a.pack_id = p.id AND a.revision = ?
      LEFT JOIN publication_revisions b ON b.pack_id = p.id AND b.revision = ?
      WHERE p.id = ?`).bind(fromRevision, toRevision, packId).first<DeltaRow>();
    if (!row) {
      const deletion = await env.DB.prepare("SELECT 1 AS found FROM studio_tombstones WHERE resource_type = 'pack' AND resource_id = ? LIMIT 1")
        .bind(packId).first();
      return deletion ? error(410, 'deleted', 'Content was deleted; check installed Pack revisions.') : error(404, 'not_found', 'Pack not found.');
    }
    if (row.deleted || row.topic_deleted) return error(410, 'deleted', 'Content was deleted; check installed Pack revisions.');
    if (!row.published || !row.topic_published) return error(403, 'unavailable', 'Content is unavailable.');
    if (!row.base_receipt || !row.target_receipt) return error(409, 'delta_unavailable', 'Revision history is unavailable. Resolve a fresh full Pack download.');
    const baseReceipt = JSON.parse(row.base_receipt) as Receipt;
    const targetReceipt = JSON.parse(row.target_receipt) as Receipt;
    for (const [receipt, expected] of [[baseReceipt, fromRevision], [targetReceipt, toRevision]] as const) {
      await verifyReceipt(env, receipt);
      if (receipt.statement.packId !== packId || receipt.statement.topicId !== row.topic_id
        || receipt.statement.revision !== expected) throw new Error('invalid_revision_identity');
    }
    // Validate the complete target before any successful/conditional response.
    // The wire delta still contains metadata and only newly required object keys.
    const target = await verifyStored(env, targetReceipt);
    const { manifest: base } = await readManifest(env, baseReceipt);
    const oldCards = new Map(base.cards.map(c => [c.id, c]));
    const newIds = new Set(target.cards.map(c => c.id));
    const oldObjects = new Set(base.objects.map(o => o.key));
    const upsertCards = target.cards.filter(c => !oldCards.has(c.id) || !sameCard(oldCards.get(c.id)!, c));
    const requiredObjects = new Set(upsertCards.map(c => c.imageReference));
    const body = JSON.stringify({ protocolVersion: 1, packId, fromRevision, toRevision,
      targetManifestSha256: targetReceipt.statement.manifestSha256,
      targetManifestUrl: `${url.origin}/content/v1/packs/${encodeURIComponent(packId)}/revisions/${toRevision}/manifest`,
      upsertCards, removeCardIds: base.cards.filter(c => !newIds.has(c.id)).map(c => c.id),
      objects: target.objects.filter(o => requiredObjects.has(o.key) && !oldObjects.has(o.key)),
    });
    const etag = `"${await hash(new TextEncoder().encode(body))}"`;
    const headers = { ...cors, ETag: etag, 'Cache-Control': 'public, max-age=60, must-revalidate',
      'Content-Type': 'application/json; charset=utf-8' };
    if (request.headers.get('If-None-Match')?.split(',').map(s => s.trim()).some(s => s === '*' || s.replace(/^W\//, '') === etag)) {
      return new Response(null, { status: 304, headers });
    }
    return new Response(body, { headers });
  } catch { return error(503, 'internal_error', 'Pack delta storage is temporarily unavailable.'); }
}

/** Anonymous sync transport; installation and safe-point application remain local. */
export async function sync(request: Request, env: Env): Promise<Response> {
  const path = new URL(request.url).pathname;
  const match = /^\/content\/v1\/packs\/([^/]+)\/delta$/.exec(path);
  if (path !== '/content/v1/sync/revisions' && !match) return error(404, 'not_found', 'Endpoint not found.');
  if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: { ...cors, 'Cache-Control': 'no-store' } });
  return match ? delta(request, env, match) : revisions(request, env);
}

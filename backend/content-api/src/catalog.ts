import type { Env } from './env';

type Item = { id: string; name: string; revision: number; topicId?: string;
  cardCount?: number; manifestSha256?: string };
type Snapshot = { id: string; scope: string; page_limit: number; expires_at: number;
  secret: string; items: string };
const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
  'Access-Control-Allow-Headers': 'If-None-Match',
  'Access-Control-Expose-Headers': 'ETag, Retry-After',
};
export function error(status: number, code: string, message: string): Response {
  return Response.json({ protocolVersion: 1, error: {
    code, message, requestId: crypto.randomUUID(), retryable: status === 503,
    currentRevision: null,
  } }, { status, headers: { ...cors, 'Cache-Control': 'no-store',
    ...(status === 503 ? { 'Retry-After': '5' } : {}) } });
}
async function hash(text: string): Promise<string> {
  const bytes = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text));
  return Array.from(new Uint8Array(bytes), b => b.toString(16).padStart(2, '0')).join('');
}
async function cursor(snapshot: Snapshot, offset: number): Promise<string> {
  return `${snapshot.id}.${offset}.${await hash(`${snapshot.secret}:${offset}`)}`;
}

export async function catalog(request: Request, env: Env): Promise<Response> {
  const url = new URL(request.url);
  if (!url.pathname.startsWith('/content/v1/')) {
    return error(426, 'unsupported_protocol', 'This content protocol is unsupported.');
  }
  const packs = url.pathname === '/content/v1/catalog/packs';
  if (!packs && url.pathname !== '/content/v1/catalog/topics') {
    return error(404, 'not_found', 'Endpoint not found.');
  }
  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: { ...cors, 'Cache-Control': 'no-store' } });
  }
  // v1 has no method_not_allowed error code; unsupported operations are invalid requests.
  if (request.method !== 'GET') return error(400, 'invalid_request', 'Use GET to read the catalog.');
  const allowed = new Set(packs ? ['topicId', 'limit', 'cursor'] : ['limit', 'cursor']);
  for (const key of url.searchParams.keys()) {
    if (!allowed.has(key) || url.searchParams.getAll(key).length !== 1) {
      return error(400, 'invalid_request', 'Invalid catalog parameters.');
    }
  }
  const rawLimit = url.searchParams.get('limit') ?? '50';
  if (!/^[1-9][0-9]?$|^100$/.test(rawLimit)) return error(400, 'invalid_request', 'Limit must be 1–100.');
  const limit = Number(rawLimit);
  const topicId = packs ? url.searchParams.get('topicId') : null;
  if (packs && (!topicId || /[\s\p{Cc}\p{Cs}]/u.test(topicId))) {
    return error(400, 'invalid_request', 'A valid topicId is required.');
  }
  const scope = JSON.stringify([packs ? 'packs' : 'topics', topicId]);
  const token = url.searchParams.get('cursor');
  if (token !== null && !/^[a-f0-9]{64}\.[1-9][0-9]*\.[a-f0-9]{64}$/.test(token)) {
    return error(400, 'invalid_request', 'Invalid cursor.');
  }
  try {
    // D1 batch gives parent state and the visible summary set one read transaction.
    const reads = await env.DB.batch([
      env.DB.prepare('SELECT published, deleted FROM catalog_topics WHERE id = ?').bind(topicId),
      env.DB.prepare(packs
        ? `SELECT p.id, p.name, p.topic_id AS topicId, p.revision,
             p.card_count AS cardCount, p.manifest_sha256 AS manifestSha256
           FROM catalog_packs p JOIN catalog_topics t ON t.id = p.topic_id
           WHERE p.topic_id = ? AND p.published = 1 AND p.deleted = 0
             AND t.published = 1 AND t.deleted = 0 ORDER BY p.id COLLATE BINARY`
        : `SELECT id, name, revision FROM catalog_topics
           WHERE published = 1 AND deleted = 0 ORDER BY id COLLATE BINARY`)
        .bind(...(packs ? [topicId] : [])),
    ]);
    if (packs) {
      const topic = reads[0].results[0] as { published: number; deleted: number } | undefined;
      if (!topic) return error(404, 'not_found', 'Topic not found.');
      if (topic.deleted) return error(410, 'deleted', 'Topic was deleted.');
      if (!topic.published) return error(403, 'unavailable', 'Topic is unavailable.');
    }
    const current = reads[1].results as Item[];
    const now = Math.floor(Date.now() / 1000);
    let snapshot: Snapshot;
    let offset = 0;
    if (token !== null) {
      const [id, position] = token.split('.');
      const saved = await env.DB.prepare('SELECT * FROM catalog_snapshots WHERE id = ?').bind(id).first<Snapshot>();
      offset = Number(position);
      if (!saved || saved.scope !== scope || saved.page_limit !== limit ||
          !Number.isSafeInteger(offset) || offset % limit !== 0 || token !== await cursor(saved, offset)) {
        return error(400, 'invalid_request', 'Cursor does not match this request.');
      }
      snapshot = saved;
    } else {
      // Deterministic within a ten-minute window so identical first-page reads
      // support conditional caching. Snapshots live ten to twenty minutes.
      const expires = (Math.floor(now / 600) + 2) * 600;
      const items = JSON.stringify(current);
      const id = await hash(JSON.stringify([scope, limit, expires, items]));
      await env.DB.prepare(`INSERT OR IGNORE INTO catalog_snapshots
        (id, scope, page_limit, expires_at, secret, items) VALUES (?, ?, ?, ?, ?, ?)`)
        .bind(id, scope, limit, expires, crypto.randomUUID(), items).run();
      snapshot = (await env.DB.prepare('SELECT * FROM catalog_snapshots WHERE id = ?').bind(id).first<Snapshot>())!;
    }
    const items = JSON.parse(snapshot.items) as Item[];
    if (token !== null && offset >= items.length) return error(400, 'invalid_request', 'Invalid cursor position.');
    const visible = new Set(current.map(item => item.id));
    if (snapshot.expires_at <= now || items.some(item => !visible.has(item.id))) {
      return error(409, 'cursor_expired', 'Catalog snapshot expired. Restart from the first page.');
    }
    const body = JSON.stringify({ protocolVersion: 1, snapshot: snapshot.id,
      items: items.slice(offset, offset + limit),
      nextCursor: offset + limit < items.length ? await cursor(snapshot, offset + limit) : null });
    const etag = `"${await hash(body)}"`;
    const headers = { ...cors, ETag: etag, 'Cache-Control': 'public, max-age=60, must-revalidate',
      'Content-Type': 'application/json; charset=utf-8' };
    const tags = request.headers.get('If-None-Match')?.split(',').map(tag => tag.trim());
    if (tags?.some(tag => tag === '*' || tag.replace(/^W\//, '') === etag)) {
      return new Response(null, { status: 304, headers });
    }
    return new Response(body, { headers });
  } catch {
    return error(503, 'internal_error', 'Catalog is temporarily unavailable.');
  }
}

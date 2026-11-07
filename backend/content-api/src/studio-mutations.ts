import type { Env } from './env';
import { authorize, StudioError, type Principal, type Action } from './studio-auth';
import { hash } from './publication';

type Kind = 'topic' | 'pack' | 'card';
type MutationAction = 'create' | 'update' | 'hide' | 'activate' | 'softDelete' | 'restore' | 'permanentDelete' | 'publish';
type Value = { name: string; topicId?: string; packId?: string; imageReference?: string; difficulty?: number };
type Operation = { resourceType: Kind; id: string; action: MutationAction; value?: Value };
type Batch = { protocolVersion: 1; aggregate: { resourceType: 'topic' | 'pack'; id: string }; operations: Operation[] };
type Entity = { resource_type: Kind; id: string; parent_id: string | null; value: string | null;
  state: 'active' | 'hidden' | 'deleted' | 'purged'; revision: number };
class MutationError extends Error {
  constructor(readonly status: number, readonly code: string, message: string,
    readonly revision: number | null = null) { super(message); }
}
const fail = (message: string): never => { throw new MutationError(422, 'validation_failed', message); };
const validId = (v: unknown): v is string => typeof v === 'string' && v.length > 0 && !/[\s\p{Cc}\p{Cs}]/u.test(v);
const validName = (v: unknown): v is string => typeof v === 'string' && v.length > 0 && v.trim() === v && !/[\p{Cc}\p{Cs}]/u.test(v);
function object(v: unknown): v is Record<string, unknown> { return !!v && typeof v === 'object' && !Array.isArray(v); }
function fields(v: unknown, required: string[]): asserts v is Record<string, unknown> {
  if (!object(v) || Object.keys(v).length !== required.length || required.some(k => !Object.hasOwn(v, k))) {
    fail('Fields must match the mutation schema; protected fields are not accepted.');
  }
}
function parse(value: unknown): Batch {
  fields(value, ['protocolVersion', 'aggregate', 'operations']);
  if (value.protocolVersion !== 1) throw new MutationError(426, 'unsupported_protocol', 'Use Studio protocol version 1.');
  fields(value.aggregate, ['resourceType', 'id']);
  if (typeof value.aggregate.resourceType !== 'string' || !['topic', 'pack'].includes(value.aggregate.resourceType) || !validId(value.aggregate.id)) fail('Invalid aggregate.');
  if (!Array.isArray(value.operations) || value.operations.length < 1 || value.operations.length > 100) fail('Commit 1–100 final operations per batch.');
  const seen = new Set<string>();
  for (const op of value.operations as unknown[]) {
    if (!object(op)) throw new MutationError(422, 'validation_failed', 'Invalid operation.');
    const hasValue = op.action === 'create' || op.action === 'update';
    fields(op, hasValue ? ['resourceType', 'id', 'action', 'value'] : ['resourceType', 'id', 'action']);
    if (typeof op.resourceType !== 'string' || !['topic', 'pack', 'card'].includes(op.resourceType) || !validId(op.id)
      || typeof op.action !== 'string' || !['create', 'update', 'hide', 'activate', 'softDelete', 'restore', 'permanentDelete', 'publish'].includes(op.action)
      || (op.action === 'activate' && op.resourceType !== 'card') || (op.action === 'publish' && op.resourceType === 'card')) fail('Invalid operation.');
    const key = JSON.stringify([op.resourceType, op.id]);
    if (seen.has(key)) fail('Use one final operation per resource.');
    seen.add(key);
    if (hasValue) {
      const keys = op.resourceType === 'topic' ? ['name'] : op.resourceType === 'pack'
        ? ['name', 'topicId'] : ['name', 'packId', 'imageReference', 'difficulty'];
      fields(op.value, keys);
      if (!validName(op.value.name)) fail('Names must be nonempty and trimmed.');
      if (op.resourceType === 'pack' && !validId(op.value.topicId)) fail('Invalid Topic relationship.');
      if (op.resourceType === 'card' && (!validId(op.value.packId) || ![1, 2, 3].includes(Number(op.value.difficulty))
        || typeof op.value.difficulty !== 'number' || typeof op.value.imageReference !== 'string'
        || !/^objects\/[a-f0-9]{64}\.(webp|png|jpg)$/.test(op.value.imageReference))) fail('Invalid Card fields.');
    }
  }
  return value as unknown as Batch;
}
function canonical(v: unknown): string {
  if (Array.isArray(v)) return `[${v.map(canonical).join(',')}]`;
  if (object(v)) return `{${Object.keys(v).sort().map(k => `${JSON.stringify(k)}:${canonical(v[k])}`).join(',')}}`;
  return JSON.stringify(v);
}
const keyOf = (kind: Kind, id: string) => JSON.stringify([kind, id]);
const live = (e: Entity | undefined) => e && e.state !== 'deleted' && e.state !== 'purged';
function response(result: { revision: number }): Response {
  return Response.json(result, { headers: { 'Cache-Control': 'no-store', ETag: `"rev-${result.revision}"` } });
}
async function image(env: Env, reference: string): Promise<void> {
  // Only operator-managed content-addressed R2 objects are accepted. There is no
  // caller-controlled URL, bucket or upload endpoint at this boundary.
  const stored = await env.CONTENT.get(reference);
  if (!stored) fail('Card image must reference an existing authorized object.');
  const bytes = new Uint8Array(await stored!.arrayBuffer());
  const ext = reference.split('.').at(-1);
  const mime = ext === 'webp' ? 'image/webp' : ext === 'png' ? 'image/png' : 'image/jpeg';
  const magic = ext === 'webp' ? bytes.length >= 12 && new TextDecoder().decode(bytes.slice(0, 4)) === 'RIFF'
    && new TextDecoder().decode(bytes.slice(8, 12)) === 'WEBP'
    : ext === 'png' ? [137, 80, 78, 71, 13, 10, 26, 10].every((b, i) => bytes[i] === b)
    : bytes.length >= 3 && bytes[0] === 255 && bytes[1] === 216 && bytes[2] === 255;
  if (!magic || stored!.httpMetadata?.contentType !== mime || await hash(bytes) !== reference.slice(8, 72)) {
    fail('Card image bytes, hash and media type must agree.');
  }
}

/** Frozen v1 batch contract. D1 executes the commit guard and all changes atomically. */
export async function mutate(request: Request, env: Env, principal: Principal, route?: { resource: string; action: Action; path: string }): Promise<Response> {

  try {
    // Bound input before parsing; read streams incrementally rather than trusting Content-Length.
    const reader = request.body?.getReader();
    if (!reader) throw new MutationError(400, 'invalid_request', 'A JSON mutation body is required.');
    let size = 0; const chunks: Uint8Array[] = [];
    while (true) {
      const { done, value } = await reader.read(); if (done) break;
      size += value.length;
      if (size > 262144) { await reader.cancel(); throw new MutationError(400, 'invalid_request', 'Mutation body exceeds 256 KiB.'); }
      chunks.push(value);
    }
    const bytes = new Uint8Array(size); let offset = 0;
    for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.length; }
    let payload: unknown;
    try { payload = JSON.parse(new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(bytes)); }
    catch { throw new MutationError(400, 'invalid_request', 'A valid JSON mutation body is required.'); }
    const batch = parse(payload);
    if (route) {
      const op = batch.operations[0];
      const expectedAction = ({ edit: 'update', 'soft-delete': 'softDelete', 'permanent-delete': 'permanentDelete' } as Record<string, string>)[route.action] ?? route.action;
      let routeId: string | undefined;
      try { routeId = route.path.split('/')[4] === undefined ? undefined : decodeURIComponent(route.path.split('/')[4]); }
      catch { throw new MutationError(400, 'invalid_request', 'Invalid resource ID.'); }
      if (batch.operations.length !== 1 || `${op.resourceType}s` !== route.resource || op.action !== expectedAction
        || (routeId !== undefined && op.id !== routeId)) fail('Item routes require one matching operation in a StudioBatch.');
    }
    for (const op of batch.operations) {
      const action = ({ update: 'edit', activate: 'edit', softDelete: 'soft-delete', permanentDelete: 'permanent-delete' } as Record<string, Action>)[op.action] ?? op.action as Action;
      authorize(principal, `${op.resourceType}s`, action);
    }
    if (batch.operations.some(op => op.action === 'publish')) throw new MutationError(501, 'internal_error', 'Publishing requires the separate validated publication workflow.');
    const match = request.headers.get('If-Match'); const none = request.headers.get('If-None-Match');
    if (match === null && none === null) throw new MutationError(428, 'precondition_required', 'Send If-Match or If-None-Match.');
    if ((match !== null && none !== null) || (none !== null && none !== '*')
      || (match !== null && (!/^"rev-[1-9][0-9]*"$/.test(match) || !Number.isSafeInteger(Number(match.slice(5, -1)))))) {
      throw new MutationError(400, 'invalid_request', 'Invalid revision precondition.');
    }
    const expected = match ? Number(match.slice(5, -1)) : 0;
    const idempotency = request.headers.get('Idempotency-Key');
    if (!validId(idempotency)) throw new MutationError(400, 'invalid_request', 'Idempotency-Key is required.');
    const canonicalRequest = canonical([batch, match, none]);
    const fingerprint = await hash(new TextEncoder().encode(canonicalRequest));
    const retry = async (): Promise<Response | undefined> => {
      const saved = await env.DB.prepare('SELECT fingerprint, result FROM studio_commits WHERE actor_id = ? AND idempotency_key = ?')
        .bind(principal.uid, idempotency).first<{ fingerprint: string; result: string }>();
      if (saved) {
        if (saved.fingerprint !== fingerprint) throw new MutationError(409, 'idempotency_conflict', 'This key was used for a different commit.');
        return response(JSON.parse(saved.result));
      }
    };
    const previous = await retry(); if (previous) return previous;
    const aggregate = batch.aggregate;
    if (batch.operations.length > 1 && batch.operations.some(op => op.resourceType === aggregate.resourceType
      && op.id === aggregate.id && ['softDelete', 'restore', 'permanentDelete'].includes(op.action))) {
      fail('Commit parent deletion, restoration or purge separately from child operations.');
    }
    const requestedTopics = batch.operations.filter(op => op.resourceType === 'pack' && op.value).map(op => op.value!.topicId!);
    // Read only this aggregate, its descendants and referenced parent Topics.
    // Generation and entities are one read transaction, preventing torn validation.
    const reads = await env.DB.batch([
      env.DB.prepare('SELECT generation FROM studio_generation WHERE id = 1'),
      env.DB.prepare(`SELECT * FROM studio_entities WHERE
        (resource_type = ? AND id = ?) OR
        (? = 'pack' AND resource_type = 'card' AND parent_id = ?) OR
        (? = 'topic' AND resource_type = 'pack' AND parent_id = ?) OR
        (? = 'topic' AND resource_type = 'card' AND parent_id IN
          (SELECT id FROM studio_entities WHERE resource_type = 'pack' AND parent_id = ?)) OR
        (resource_type = 'topic' AND (id IN (SELECT parent_id FROM studio_entities WHERE resource_type = 'pack' AND id = ?)
          OR id IN (SELECT value FROM json_each(?))))`)
        .bind(aggregate.resourceType, aggregate.id, aggregate.resourceType, aggregate.id, aggregate.resourceType, aggregate.id,
          aggregate.resourceType, aggregate.id, aggregate.id, JSON.stringify(requestedTopics)),
    ]);
    const generation = (reads[0].results[0] as { generation: number }).generation;
    const entities = new Map((reads[1].results as Entity[]).map(e => [keyOf(e.resource_type, e.id), e]));
    const aggregateKey = keyOf(aggregate.resourceType, aggregate.id);
    const current = entities.get(aggregateKey);
    if ((current?.revision ?? 0) !== expected) throw new MutationError(412, 'revision_conflict', 'Refresh the aggregate before committing.', current?.revision ?? null);
    if (current?.state === 'purged') throw new MutationError(410, 'deleted', 'This identity was permanently deleted.');
    if (expected === 0 && !batch.operations.some(op => op.resourceType === aggregate.resourceType && op.id === aggregate.id && op.action === 'create')) fail('New aggregates require their create operation.');
    const revision = expected + 1;
    if (!Number.isSafeInteger(revision)) fail('Revision range exhausted.');
    const changed = new Map<string, { entity: Entity; action: string }>();
    const put = (e: Entity, action: string) => { entities.set(keyOf(e.resource_type, e.id), e); changed.set(keyOf(e.resource_type, e.id), { entity: e, action }); };
    // Create/edit the Pack first so a create batch can include Cards in any order.
    const verifiedImages = new Set<string>();
    const operations = [...batch.operations].sort((a, b) => Number(a.resourceType === 'card') - Number(b.resourceType === 'card'));
    for (const op of operations) {
      if (aggregate.resourceType === 'topic' ? op.resourceType !== 'topic' || op.id !== aggregate.id
        : op.resourceType === 'topic' || (op.resourceType === 'pack' && op.id !== aggregate.id)) fail('Operation is outside the aggregate.');
      const key = keyOf(op.resourceType, op.id); const old = entities.get(key);
      const parentId = op.resourceType === 'topic' ? null : op.resourceType === 'pack' ? op.value?.topicId ?? old?.parent_id : aggregate.id;
      // A globally unique Card may exist outside the scoped aggregate. The SQL
      // INSERT (never upsert for create) catches collisions without overwriting it.
      if (op.resourceType === 'card' && ((old && old.parent_id !== aggregate.id) || (op.value && op.value.packId !== aggregate.id))) fail('Card must belong to this Pack.');
      if (op.resourceType === 'pack' && old && op.value && old.parent_id !== op.value.topicId) fail('Changing a Pack Topic requires a separate migration.');
      if (op.action === 'create' && old) fail('Identity already exists and cannot be reused.');
      if (op.action !== 'create' && !old) throw new MutationError(404, 'not_found', 'Resource not found in this aggregate.');
      if (old?.state === 'purged') throw new MutationError(410, 'deleted', 'This identity was permanently deleted.');
      if (op.action === 'restore' || op.action === 'permanentDelete') {
        if (old?.state !== 'deleted') fail('Restore and purge require prior soft deletion.');
      } else if (old?.state === 'deleted') throw new MutationError(410, 'deleted', 'Restore deleted content before editing it.');
      const parent = op.resourceType === 'topic' ? undefined : entities.get(keyOf(op.resourceType === 'pack' ? 'topic' : 'pack', parentId!));
      if (op.resourceType !== 'topic' && op.action !== 'permanentDelete' && op.action !== 'softDelete' && !live(parent)) fail('Parent must exist and must not be deleted.');
      if (op.action === 'permanentDelete' && [...entities.values()].some(e => e.parent_id === op.id
        && e.resource_type === (op.resourceType === 'topic' ? 'pack' : op.resourceType === 'pack' ? 'card' : '') && e.state !== 'purged')) fail('Purge children before their parent.');
      if (op.value?.imageReference && !verifiedImages.has(op.value.imageReference)) {
        await image(env, op.value.imageReference);
        verifiedImages.add(op.value.imageReference);
      }
      const state = op.action === 'softDelete' ? 'deleted' : op.action === 'permanentDelete' ? 'purged'
        : op.action === 'hide' || op.action === 'restore' ? 'hidden' : op.action === 'activate' || op.action === 'create' ? 'active' : old!.state;
      put({ resource_type: op.resourceType, id: op.id, parent_id: parentId!,
        value: op.action === 'permanentDelete' ? null : op.value ? canonical(op.value) : old!.value,
        state, revision }, op.action);
      if (op.action === 'softDelete' && op.resourceType !== 'card') {
        // Deletion cascades; restore is explicit and never republishes children.
        const packs = new Set(op.resourceType === 'pack' ? [op.id] : [...entities.values()]
          .filter(e => e.resource_type === 'pack' && e.parent_id === op.id).map(e => e.id));
        for (const e of [...entities.values()].sort((a, b) => Number(a.resource_type === 'card') - Number(b.resource_type === 'card'))) {
          if (e.state === 'purged' || e.id === op.id && e.resource_type === op.resourceType) continue;
          if ((e.resource_type === 'pack' && op.resourceType === 'topic' && e.parent_id === op.id)
            || (e.resource_type === 'card' && packs.has(e.parent_id!))) {
            const packRevision = op.resourceType === 'pack' ? revision :
              entities.get(keyOf('pack', e.resource_type === 'pack' ? e.id : e.parent_id!))!.revision + (e.resource_type === 'pack' ? 1 : 0);
            if (!Number.isSafeInteger(packRevision)) fail('Revision range exhausted.');
            put({ ...e, state: 'deleted', revision: packRevision }, 'softDelete');
          }
        }
      }
    }
    // A card-only batch still advances its Pack exactly once.
    if (!changed.has(aggregateKey)) {
      if (!live(entities.get(aggregateKey)) && !(current?.state === 'deleted' && batch.operations.every(op => op.action === 'permanentDelete'))) fail('Aggregate must exist and must not be deleted.');
      put({ ...entities.get(aggregateKey)!, revision }, 'batch');
    }
    const committedAt = new Date().toISOString(); const batchId = crypto.randomUUID();
    const result = { protocolVersion: 1, aggregate, revision, committedAt, actorId: principal.uid };
    const statements = [env.DB.prepare('INSERT INTO studio_commits VALUES (?, ?, ?, ?, ?, ?, ?)')
      .bind(principal.uid, idempotency, fingerprint, canonicalRequest, JSON.stringify(result), batchId, generation)];
    for (const { entity: e, action } of changed.values()) {
      const isCreate = action === 'create';
      statements.push(env.DB.prepare(isCreate ? 'INSERT INTO studio_entities VALUES (?, ?, ?, ?, ?, ?)' :
        `UPDATE studio_entities SET parent_id = ?3, value = ?4, state = ?5, revision = ?6 WHERE resource_type = ?1 AND id = ?2`)
        .bind(e.resource_type, e.id, e.parent_id, e.value, e.state, e.revision));
      statements.push(env.DB.prepare('INSERT INTO studio_audit VALUES (?, ?, ?, ?, ?, ?, ?, ?)')
        .bind(batchId, principal.uid, principal.role, e.resource_type, e.id, action, e.revision, committedAt));
      if (action === 'softDelete') statements.push(env.DB.prepare('INSERT INTO studio_tombstones VALUES (?, ?, ?, ?)')
        .bind(e.resource_type, e.id, e.revision, committedAt));
      // Immediately suppress previously published artifacts for visibility/deletion
      // changes. Draft product edits do not rewrite immutable manifests (T25/T35).
      if (['hide', 'softDelete', 'restore', 'permanentDelete'].includes(action)) {
        const table = e.resource_type === 'topic' ? 'catalog_topics' : 'catalog_packs';
        statements.push(e.resource_type === 'card'
          ? env.DB.prepare('UPDATE catalog_packs SET published = 0 WHERE id = ?').bind(e.parent_id)
          : env.DB.prepare(`UPDATE ${table} SET published = 0, deleted = ? WHERE id = ?`)
            .bind(Number(e.state === 'deleted' || e.state === 'purged'), e.id));
      }
    }
    try { await env.DB.batch(statements); }
    catch (error) {
      // A racing identical request may already have committed. Return its saved
      // result before checking any revision, exactly like a later retry.
      const raced = await retry(); if (raced) return raced;
      if (String(error).includes('studio_conflict')) {
        const latest = await env.DB.prepare('SELECT revision FROM studio_entities WHERE resource_type = ? AND id = ?')
          .bind(aggregate.resourceType, aggregate.id).first<{ revision: number }>();
        throw new MutationError(412, 'revision_conflict', 'Content changed during validation. Refresh and retry.', latest?.revision ?? null);
      }
      if (String(error).includes('UNIQUE constraint failed: studio_entities')) fail('Identity already exists and cannot be reused.');
      throw error;
    }
    return response(result);
  } catch (error) {
    const e = error instanceof MutationError ? error : error instanceof StudioError
      ? new MutationError(error.status, error.code, 'Studio access is forbidden.')
      : new MutationError(503, 'internal_error', 'Studio storage is temporarily unavailable.');
    return Response.json({ protocolVersion: 1, error: { code: e.code, message: e.message,
      requestId: crypto.randomUUID(), retryable: e.status === 503, currentRevision: e.revision } },
    { status: e.status, headers: { 'Cache-Control': 'no-store' } });
  }
}

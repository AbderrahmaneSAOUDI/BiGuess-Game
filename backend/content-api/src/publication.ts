import type { Env } from './env';

export const immutable = 'public, max-age=31536000, immutable';
export const hash = async (bytes: Uint8Array): Promise<string> =>
  Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', bytes)))
    .map((byte) => byte.toString(16).padStart(2, '0')).join('');
export const decode = (value: string): Uint8Array => Uint8Array.from(atob(value), (c) => c.charCodeAt(0));
const encode = (value: string) => new TextEncoder().encode(value);
interface Statement {
  archiveSha256: string; archiveSizeBytes: number; domain: string;
  manifestSha256: string; manifestSizeBytes: number;
  packId: string; revision: number; topicId: string;
}
export interface Receipt {
  schemaVersion: number; algorithm: string; keyId: string;
  statement: Statement; signature: string;
}
export interface Image { key: string; sha256: string; sizeBytes: number; mediaType: string }
interface Rights { rights_status: string; permission_to_publish: boolean; public_test_publishable: boolean; source: string; license: string; attribution: string }
export interface Manifest {
  schemaVersion: number; kind: string;
  pack: { id: string; name: string; revision: number; topicId: string }; topic: { id: string; name: string };
  objects: Image[]; cards: { id: string; name: string; difficulty: number; packId: string; imageReference: string }[];
  provenance: { mode: string; packRights: Rights; cardRights: (Rights & { id: string })[] };
}
export interface Bundle {
  receipt: Receipt; manifest: string; archive: string; objects: Record<string, string>;
}
const require = (condition: unknown): void => { if (!condition) throw new Error('invalid_publication'); };
const record = (value: unknown, fields: string[]): void => {
  require(value && typeof value === 'object' && !Array.isArray(value));
  require(Object.keys(value as object).length === fields.length && fields.every(f => Object.hasOwn(value as object, f)));
};
const identifier = (value: unknown): boolean => typeof value === 'string' && value.length > 0 && !/[\s\p{Cc}\p{Cs}]/u.test(value);
const name = (value: unknown): boolean => typeof value === 'string' && value.length > 0 && value.trim() === value && !/[\p{Cc}\p{Cs}]/u.test(value);
const digest = (value: unknown): boolean => typeof value === 'string' && /^[0-9a-f]{64}$/.test(value);
const canonical = (value: unknown): string => {
  if (Array.isArray(value)) return `[${value.map(canonical).join(',')}]`;
  if (value && typeof value === 'object') return `{${Object.keys(value).sort().map(k => `${JSON.stringify(k)}:${canonical((value as Record<string, unknown>)[k])}`).join(',')}}`;
  return JSON.stringify(value);
};
// Unicode code point order equals UTF-8 byte order for valid scalar IDs.
const compare = (a: string, b: string): number => {
  const x = Array.from(a, c => c.codePointAt(0)!); const y = Array.from(b, c => c.codePointAt(0)!);
  for (let i = 0; i < Math.min(x.length, y.length); i++) if (x[i] !== y[i]) return x[i] - y[i];
  return x.length - y.length;
};
const ordered = (values: string[]): boolean => values.every((v, i) => i === 0 || compare(values[i - 1], v) < 0);
function rights(value: Rights, card = false): void {
  record(value, [...(card ? ['id'] : []), 'rights_status', 'permission_to_publish', 'public_test_publishable', 'source', 'license', 'attribution']);
  require(value.rights_status === 'cleared' && value.permission_to_publish === true && value.public_test_publishable === true);
  require(name(value.source) && name(value.license) && name(value.attribution));
}
function validateManifest(manifest: Manifest, s: Statement): void {
  record(manifest, ['schemaVersion', 'kind', 'topic', 'pack', 'cards', 'objects', 'provenance']);
  record(manifest.topic, ['id', 'name']); record(manifest.pack, ['id', 'topicId', 'name', 'revision']);
  record(manifest.provenance, ['mode', 'packRights', 'cardRights']);
  require(manifest.schemaVersion === 1 && manifest.kind === 'full' && manifest.provenance.mode === 'cleared-test');
  require(manifest.pack.id === s.packId && manifest.pack.revision === s.revision &&
    manifest.topic.id === s.topicId && manifest.pack.topicId === s.topicId);
  require(identifier(s.packId) && identifier(s.topicId) && name(manifest.pack.name) && name(manifest.topic.name));
  require(Array.isArray(manifest.cards) && manifest.cards.length >= 2 && Array.isArray(manifest.objects) && manifest.objects.length >= 1);
  for (const c of manifest.cards) {
    record(c, ['id', 'name', 'difficulty', 'packId', 'imageReference']);
    require(identifier(c.id) && name(c.name) && typeof c.difficulty === 'number' && [1, 2, 3].includes(c.difficulty));
    require(c.packId === s.packId && typeof c.imageReference === 'string');
  }
  require(ordered(manifest.cards.map(c => c.id)) && ordered(manifest.objects.map(o => o.key)));
  const keys = new Set(manifest.objects.map(o => o.key));
  for (const row of manifest.objects) {
    record(row, ['key', 'sha256', 'sizeBytes', 'mediaType']);
    const ext = { 'image/webp': 'webp', 'image/png': 'png', 'image/jpeg': 'jpg' }[row.mediaType];
    require(typeof row.mediaType === 'string' && Number.isSafeInteger(row.sizeBytes) && row.sizeBytes > 0);
    require(ext && digest(row.sha256) && row.key === `objects/${row.sha256}.${ext}`);
  }
  require(manifest.cards.every(c => keys.has(c.imageReference)));
  require(manifest.objects.every(o => manifest.cards.some(c => c.imageReference === o.key)));
  rights(manifest.provenance.packRights);
  require(Array.isArray(manifest.provenance.cardRights) && ordered(manifest.provenance.cardRights.map(r => r.id)));
  require(manifest.provenance.cardRights.length === manifest.cards.length);
  for (let i = 0; i < manifest.cards.length; i++) {
    const row = manifest.provenance.cardRights[i]; rights(row, true);
    require(row.id === manifest.cards[i].id);
  }
}
function verifyImage(bytes: Uint8Array, image: Image): void {
  const ascii = (start: number, end: number) => new TextDecoder().decode(bytes.slice(start, end));
  const valid = image.mediaType === 'image/webp' ? bytes.length >= 12 && ascii(0, 4) === 'RIFF' && ascii(8, 12) === 'WEBP'
    : image.mediaType === 'image/png' ? [137, 80, 78, 71, 13, 10, 26, 10].every((v, i) => bytes[i] === v)
    : image.mediaType === 'image/jpeg' && bytes.length >= 3 && bytes[0] === 255 && bytes[1] === 216 && bytes[2] === 255;
  require(valid);
}
export const statementBytes = (s: Statement): Uint8Array => encode(JSON.stringify({
  archiveSha256: s.archiveSha256, archiveSizeBytes: s.archiveSizeBytes, domain: s.domain,
  manifestSha256: s.manifestSha256, manifestSizeBytes: s.manifestSizeBytes,
  packId: s.packId, revision: s.revision, topicId: s.topicId,
}) + '\n');

export async function verifyReceipt(env: Env, receipt: Receipt): Promise<void> {
  record(receipt, ['schemaVersion', 'algorithm', 'keyId', 'statement', 'signature']);
  const s = receipt.statement;
  record(s, ['archiveSha256', 'archiveSizeBytes', 'domain', 'manifestSha256', 'manifestSizeBytes', 'packId', 'revision', 'topicId']);
  require(identifier(s.packId) && identifier(s.topicId) && digest(receipt.keyId) && typeof receipt.signature === 'string');
  require(receipt.schemaVersion === 1 && receipt.algorithm === 'Ed25519');
  require(s.domain === 'biguess-pack-publication-v1');
  require(Number.isSafeInteger(s.revision) && s.revision > 0);
  require(Number.isSafeInteger(s.archiveSizeBytes) && s.archiveSizeBytes > 0);
  require(Number.isSafeInteger(s.manifestSizeBytes) && s.manifestSizeBytes > 0);
  require(digest(s.manifestSha256) && digest(s.archiveSha256));
  const keys = JSON.parse(env.PUBLICATION_KEYS ?? '{}') as Record<string, string>;
  require(Object.hasOwn(keys, receipt.keyId));
  const spki = decode(keys[receipt.keyId]);
  require(await hash(spki) === receipt.keyId);
  const key = await crypto.subtle.importKey('spki', spki, 'Ed25519', false, ['verify']);
  require(await crypto.subtle.verify('Ed25519', key, decode(receipt.signature), statementBytes(s)));
}

export async function verifyBytes(bytes: Uint8Array, sha256: string, size: number): Promise<void> {
  require(bytes.byteLength === size && await hash(bytes) === sha256);
}

export async function readManifest(env: Env, receipt: Receipt): Promise<{ bytes: Uint8Array; manifest: Manifest }> {
  const s = receipt.statement;
  const object = await env.CONTENT.get(`manifests/${s.manifestSha256}.json`);
  require(object);
  const bytes = new Uint8Array(await object!.arrayBuffer());
  await verifyBytes(bytes, s.manifestSha256, s.manifestSizeBytes);
  const manifest = JSON.parse(new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(bytes)) as Manifest;
  validateManifest(manifest, s);
  require(new TextDecoder().decode(bytes) === canonical(manifest) + '\n');
  return { bytes, manifest };
}

// Conditional create prevents racing writers replacing an existing immutable key.
async function put(env: Env, key: string, bytes: Uint8Array, sha256: string, mediaType: string): Promise<void> {
  await verifyBytes(bytes, sha256, bytes.length);
  await env.CONTENT.put(key, bytes, {
    onlyIf: { etagDoesNotMatch: '*' }, sha256,
    httpMetadata: { contentType: mediaType, cacheControl: immutable },
  });
  const stored = await env.CONTENT.get(key);
  require(stored);
  await verifyBytes(new Uint8Array(await stored!.arrayBuffer()), sha256, bytes.length);
}

type AdministrativeEntity = { resource_type: 'topic' | 'pack' | 'card'; id: string; parent_id: string | null;
  value: string | null; state: 'active' | 'hidden' | 'deleted' | 'purged'; revision: number };

async function administrativeProjection(env: Env, manifest: Manifest, s: Statement, expectedRevision: number): Promise<{ statements: D1PreparedStatement[]; resumePublished: boolean }> {
  const reads = await env.DB.batch([
    env.DB.prepare('SELECT generation FROM studio_generation WHERE id = 1'),
    env.DB.prepare(`SELECT * FROM studio_entities WHERE (resource_type = 'topic' AND id = ?)
      OR (resource_type = 'pack' AND id = ?) OR (resource_type = 'card' AND
        (parent_id = ? OR id IN (SELECT value FROM json_each(?))))`)
      .bind(s.topicId, s.packId, s.packId, JSON.stringify(manifest.cards.map(c => c.id))),
    env.DB.prepare(`SELECT h.revision, r.receipt FROM publication_heads h JOIN publication_revisions r
      ON r.pack_id = h.pack_id AND r.revision = h.revision WHERE h.pack_id = ?`).bind(s.packId),
    env.DB.prepare("SELECT MAX(revision) AS revision FROM studio_tombstones WHERE resource_type = 'pack' AND resource_id = ?").bind(s.packId),
    env.DB.prepare('SELECT resume_published FROM publication_suppression WHERE pack_id = ?').bind(s.packId),
  ]);
  const generation = (reads[0].results[0] as { generation: number }).generation;
  const rows = reads[1].results as AdministrativeEntity[];
  const topic = rows.find(e => e.resource_type === 'topic');
  const pack = rows.find(e => e.resource_type === 'pack');
  const head = reads[2].results[0] as { revision: number; receipt: string } | undefined;
  const tombstone = (reads[3].results[0] as { revision: number | null }).revision;
  require((head?.revision ?? 0) === expectedRevision && s.revision > expectedRevision);
  require(tombstone === null || s.revision > tombstone);
  require(!topic || (topic.state !== 'deleted' && topic.state !== 'purged' && JSON.parse(topic.value!).name === manifest.topic.name));
  require(!pack || (pack.state !== 'deleted' && pack.state !== 'purged' && pack.parent_id === s.topicId && s.revision >= pack.revision));
  const cards = new Map(rows.filter(e => e.resource_type === 'card').map(e => [e.id, e]));
  // Migrations can fence old Topic/Pack projections without R2 reads. Hydrate any
  // missing authoring Cards lazily from the verified immutable previous snapshot.
  if (head) {
    const previous = JSON.parse(head.receipt) as Receipt;
    await verifyReceipt(env, previous);
    const { manifest: base } = await readManifest(env, previous);
    for (const card of base.cards) if (!cards.has(card.id)) cards.set(card.id, {
      resource_type: 'card', id: card.id, parent_id: s.packId, value: canonical({
        name: card.name, packId: card.packId, imageReference: card.imageReference, difficulty: card.difficulty,
      }), state: 'active', revision: head.revision,
    });
  }
  const product = (card: Manifest['cards'][number]) => ({ name: card.name, packId: card.packId,
    imageReference: card.imageReference, difficulty: card.difficulty });
  const dirty = pack && pack.revision > (head?.revision ?? 0);
  if (dirty) {
    require(s.revision === pack.revision && canonical(JSON.parse(pack.value!)) === canonical({ name: manifest.pack.name, topicId: s.topicId }));
    const visible = [...cards.values()].filter(e => e.parent_id === s.packId && e.state === 'active');
    require(visible.length === manifest.cards.length);
    require(manifest.cards.every(card => cards.get(card.id)?.state === 'active' && canonical(JSON.parse(cards.get(card.id)!.value!)) === canonical(product(card))));
  }
  for (const card of manifest.cards) {
    const old = cards.get(card.id);
    require(!old || (old.parent_id === s.packId && old.state !== 'deleted' && old.state !== 'purged'));
  }
  const statements = [env.DB.prepare('INSERT INTO publication_commits VALUES (?, ?, ?)').bind(s.packId, s.revision, generation)];
  if (!topic) statements.push(env.DB.prepare('INSERT INTO studio_entities VALUES (?, ?, NULL, ?, ?, ?)')
    .bind('topic', s.topicId, canonical({ name: manifest.topic.name }), 'active', 1));
  const store = (entity: AdministrativeEntity, existed: boolean) => statements.push(env.DB.prepare(existed
    ? 'UPDATE studio_entities SET parent_id = ?3, value = ?4, state = ?5, revision = ?6 WHERE resource_type = ?1 AND id = ?2'
    : 'INSERT INTO studio_entities VALUES (?, ?, ?, ?, ?, ?)')
    .bind(entity.resource_type, entity.id, entity.parent_id, entity.value, entity.state, entity.revision));
  store({ resource_type: 'pack', id: s.packId, parent_id: s.topicId,
    value: canonical({ name: manifest.pack.name, topicId: s.topicId }), state: pack?.state ?? 'active', revision: s.revision }, !!pack);
  const included = new Set(manifest.cards.map(c => c.id));
  const existed = new Set(rows.filter(e => e.resource_type === 'card').map(e => e.id));
  for (const card of manifest.cards) store({ resource_type: 'card', id: card.id, parent_id: s.packId,
    value: canonical(product(card)), state: 'active', revision: s.revision }, existed.has(card.id));
  for (const card of cards.values()) if (!included.has(card.id) && card.parent_id === s.packId && card.state !== 'deleted' && card.state !== 'purged') {
    store({ ...card, state: 'hidden', revision: s.revision }, existed.has(card.id));
  }
  return { statements, resumePublished: !!dirty && pack?.state === 'active'
    && (reads[4].results[0] as { resume_published: number } | undefined)?.resume_published === 1 };
}

/** Trusted-operator primitive only; Studio approval/publishing is a separate T35 boundary. */
export async function publish(env: Env, bundle: Bundle, expectedRevision: number): Promise<void> {
  await verifyReceipt(env, bundle.receipt);
  require(Number.isSafeInteger(expectedRevision) && expectedRevision >= 0);
  const s = bundle.receipt.statement;
  const manifestBytes = decode(bundle.manifest);
  const archive = decode(bundle.archive);
  await verifyBytes(manifestBytes, s.manifestSha256, s.manifestSizeBytes);
  await verifyBytes(archive, s.archiveSha256, s.archiveSizeBytes);
  await put(env, `manifests/${s.manifestSha256}.json`, manifestBytes, s.manifestSha256, 'application/json');
  const { manifest } = await readManifest(env, bundle.receipt);
  require(Object.keys(bundle.objects).length === manifest.objects.length);
  for (const row of manifest.objects) {
    require(Object.hasOwn(bundle.objects, row.key));
    const bytes = decode(bundle.objects[row.key]);
    await verifyBytes(bytes, row.sha256, row.sizeBytes);
    verifyImage(bytes, row);
    await put(env, row.key, bytes, row.sha256, row.mediaType);
  }
  await put(env, `archives/${s.archiveSha256}.biguesspack`, archive, s.archiveSha256, 'application/zip');
  // Recheck every stored artifact before the sole visibility commit. No deletes/overwrites.
  await verifyStored(env, bundle.receipt);
  const administrative = await administrativeProjection(env, manifest, s, expectedRevision);
  const receipt = JSON.stringify(bundle.receipt);
  // Transaction + SQL trigger enforce CAS and swap current/previous atomically.
  await env.DB.batch([
    ...administrative.statements,
    env.DB.prepare('INSERT INTO publication_topics (topic_id) VALUES (?) ON CONFLICT DO NOTHING').bind(s.topicId),
    env.DB.prepare('INSERT INTO publication_revisions VALUES (?, ?, ?, ?, ?)')
      .bind(s.packId, s.topicId, s.revision, expectedRevision, receipt),
    env.DB.prepare(`INSERT INTO catalog_topics (id, name, revision, published)
      VALUES (?, ?, 1, 1) ON CONFLICT(id) DO NOTHING`).bind(s.topicId, manifest.topic.name),
    env.DB.prepare(`INSERT INTO catalog_packs
      (id, topic_id, name, revision, card_count, manifest_sha256, published)
      VALUES (?, ?, ?, ?, ?, ?, 1) ON CONFLICT(id) DO UPDATE SET
      name = excluded.name, revision = excluded.revision,
      card_count = excluded.card_count, manifest_sha256 = excluded.manifest_sha256`)
      .bind(s.packId, s.topicId, manifest.pack.name, s.revision, manifest.cards.length, s.manifestSha256),
    env.DB.prepare('UPDATE catalog_packs SET published = 1 WHERE id = ? AND deleted = 0 AND ? = 1')
      .bind(s.packId, Number(administrative.resumePublished)),
    env.DB.prepare('DELETE FROM publication_suppression WHERE pack_id = ?').bind(s.packId),
  ]);
}

export async function verifyStored(env: Env, receipt: Receipt): Promise<Manifest> {
  await verifyReceipt(env, receipt);
  const { manifest } = await readManifest(env, receipt);
  for (const row of manifest.objects) {
    const object = await env.CONTENT.get(row.key);
    require(object);
    const bytes = new Uint8Array(await object!.arrayBuffer());
    await verifyBytes(bytes, row.sha256, row.sizeBytes);
    verifyImage(bytes, row);
  }
  const s = receipt.statement;
  const archive = await env.CONTENT.get(`archives/${s.archiveSha256}.biguesspack`);
  require(archive);
  await verifyBytes(new Uint8Array(await archive!.arrayBuffer()), s.archiveSha256, s.archiveSizeBytes);
  return manifest;
}

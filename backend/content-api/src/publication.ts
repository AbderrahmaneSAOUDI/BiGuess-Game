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
interface Image { key: string; sha256: string; sizeBytes: number; mediaType: string }
interface Manifest {
  schemaVersion: number; kind: string;
  pack: { id: string; name: string; revision: number; topicId: string }; topic: { id: string; name: string };
  objects: Image[]; cards: { id: string; name: string; difficulty: number; packId: string; imageReference: string }[];
  provenance: { mode: string };
}
export interface Bundle {
  receipt: Receipt; manifest: string; archive: string; objects: Record<string, string>;
}
const require = (condition: unknown): void => { if (!condition) throw new Error('invalid_publication'); };
export const statementBytes = (s: Statement): Uint8Array => encode(JSON.stringify({
  archiveSha256: s.archiveSha256, archiveSizeBytes: s.archiveSizeBytes, domain: s.domain,
  manifestSha256: s.manifestSha256, manifestSizeBytes: s.manifestSizeBytes,
  packId: s.packId, revision: s.revision, topicId: s.topicId,
}) + '\n');

export async function verifyReceipt(env: Env, receipt: Receipt): Promise<void> {
  const s = receipt.statement;
  require(receipt.schemaVersion === 1 && receipt.algorithm === 'Ed25519');
  require(s.domain === 'biguess-pack-publication-v1');
  require(Number.isSafeInteger(s.revision) && s.revision > 0);
  require(Number.isSafeInteger(s.archiveSizeBytes) && s.archiveSizeBytes > 0);
  require(Number.isSafeInteger(s.manifestSizeBytes) && s.manifestSizeBytes > 0);
  require(/^[0-9a-f]{64}$/.test(s.manifestSha256) && /^[0-9a-f]{64}$/.test(s.archiveSha256));
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
  require(manifest.schemaVersion === 1 && manifest.kind === 'full' && manifest.provenance.mode === 'cleared-test');
  require(manifest.pack.id === s.packId && manifest.pack.revision === s.revision &&
    manifest.topic.id === s.topicId && manifest.pack.topicId === s.topicId);
  const id = (value: string) => typeof value === 'string' && value.length > 0 && !/[\s\p{Cc}\p{Cs}]/u.test(value);
  const name = (value: string) => typeof value === 'string' && value.length > 0 && value.trim() === value;
  require(id(s.packId) && id(s.topicId) && name(manifest.pack.name) && name(manifest.topic.name));
  require(manifest.cards.every(c => id(c.id) && name(c.name) && [1, 2, 3].includes(c.difficulty)));
  require(manifest.cards.length >= 2 && new Set(manifest.cards.map((c) => c.id)).size === manifest.cards.length);
  const keys = new Set(manifest.objects.map((o) => o.key));
  require(keys.size === manifest.objects.length);
  for (const row of manifest.objects) {
    const ext = { 'image/webp': 'webp', 'image/png': 'png', 'image/jpeg': 'jpg' }[row.mediaType];
    require(Number.isSafeInteger(row.sizeBytes) && row.sizeBytes > 0);
    require(ext && /^[0-9a-f]{64}$/.test(row.sha256) && row.key === `objects/${row.sha256}.${ext}`);
  }
  require(manifest.cards.every((c) => c.packId === s.packId && keys.has(c.imageReference)));
  require(manifest.objects.every((o) => manifest.cards.some((c) => c.imageReference === o.key)));
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
    await put(env, row.key, bytes, row.sha256, row.mediaType);
  }
  await put(env, `archives/${s.archiveSha256}.biguesspack`, archive, s.archiveSha256, 'application/zip');
  // Recheck every stored artifact before the sole visibility commit. No deletes/overwrites.
  await verifyStored(env, bundle.receipt);
  const receipt = JSON.stringify(bundle.receipt);
  // Transaction + SQL trigger enforce CAS and swap current/previous atomically.
  await env.DB.batch([
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
  ]);
}

export async function verifyStored(env: Env, receipt: Receipt): Promise<void> {
  await verifyReceipt(env, receipt);
  const { manifest } = await readManifest(env, receipt);
  for (const row of manifest.objects) {
    const object = await env.CONTENT.get(row.key);
    require(object);
    await verifyBytes(new Uint8Array(await object!.arrayBuffer()), row.sha256, row.sizeBytes);
  }
  const s = receipt.statement;
  const archive = await env.CONTENT.get(`archives/${s.archiveSha256}.biguesspack`);
  require(archive);
  await verifyBytes(new Uint8Array(await archive!.arrayBuffer()), s.archiveSha256, s.archiveSizeBytes);
}

import assert from 'node:assert/strict';
import { test } from 'node:test';
import { readFileSync, writeFileSync, cpSync, mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { execFileSync } from 'node:child_process';
import { createHash, generateKeyPairSync, verify, sign } from 'node:crypto';
import { Miniflare, convertV4MiniflareOptions } from 'miniflare';
import { root } from '../scripts/local.mjs';
import { prepare } from '../scripts/prepare.mjs';

const hash = bytes => createHash('sha256').update(bytes).digest('hex');
const canonical = value => Array.isArray(value) ? `[${value.map(canonical).join(',')}]`
  : value && typeof value === 'object' ? `{${Object.keys(value).sort().map(k => `${JSON.stringify(k)}:${canonical(value[k])}`).join(',')}}`
  : JSON.stringify(value);
function rewrite(bundle, edit) {
  bundle = structuredClone(bundle);
  const manifest = JSON.parse(Buffer.from(bundle.manifest, 'base64'));
  edit(manifest, bundle);
  const bytes = Buffer.from(canonical(manifest) + '\n');
  bundle.manifest = bytes.toString('base64');
  bundle.receipt.statement.manifestSha256 = hash(bytes);
  bundle.receipt.statement.manifestSizeBytes = bytes.length;
  bundle.receipt.signature = sign(null, Buffer.from(JSON.stringify(bundle.receipt.statement) + '\n'), privateKey).toString('base64');
  return bundle;
}
const { privateKey, publicKey } = generateKeyPairSync('ed25519');
const pem = privateKey.export({ type: 'pkcs8', format: 'pem' });
const temporary = mkdtempSync(join(tmpdir(), 'biguess-publication-'));
const fixtures = new Map();
for (const revision of [1, 2, 3, 4]) {
  const archive = join(temporary, `${revision}.biguesspack`);
  execFileSync('python3', ['../../scripts/export_pack.py', 'fixture', '../../test/fixtures/cleared_shapes/pack.json',
    '--revision', String(revision), '--output', archive], { cwd: root });
  fixtures.set(revision, prepare(archive, pem));
}
process.on('exit', () => rmSync(temporary, { recursive: true, force: true }));
// Build a separate test harness, never a public HTTP publishing route.
execFileSync(process.execPath, ['node_modules/wrangler/bin/wrangler.js', 'deploy', 'test/publication-worker.ts',
  '--env', 'staging', '--dry-run', '--outdir', join(temporary, 'worker')], { cwd: root, stdio: 'pipe' });

function validate(type, value) {
  execFileSync('python3', ['-c', 'import json,sys; sys.path.insert(0,"../../scripts"); from validate_content_contract import validate; validate(sys.argv[1],json.load(sys.stdin))', type],
    { cwd: root, input: JSON.stringify(value), stdio: 'pipe' });
}
async function setup(t) {
  const mf = new Miniflare(convertV4MiniflareOptions({ modules: true,
    modulesRoot: join(temporary, 'worker'), scriptPath: join(temporary, 'worker/publication-worker.js'), compatibilityDate: '2026-11-01',
    bindings: { APP_ENV: 'staging', PUBLICATION_KEYS: JSON.stringify(fixtures.get(1).trustedKeys) },
    d1Databases: { DB: 'publication-test' }, r2Buckets: { CONTENT: 'publication-test' } }));
  t.after(() => mf.dispose());
  const db = await mf.getD1Database('DB');
  for (const file of ['0002_catalog.sql', '0003_publications.sql', '0004_studio.sql', '0005_distribution.sql']) {
    const sql = readFileSync(new URL(`../migrations/${file}`, import.meta.url), 'utf8')
      .split('\n').filter(line => !line.trim().startsWith('--')).join(' ');
    await db.exec(sql);
  }
  const bucket = await mf.getR2Bucket('CONTENT');
  const request = (path, options) => mf.dispatchFetch(`https://content.example${path}`, options);
  const packId = fixtures.get(1).receipt.statement.packId;
  const topicId = fixtures.get(1).receipt.statement.topicId;
  const base = `/content/v1/packs/${packId}`;
  const publish = (revision, expectedRevision, options = {}, bundle = fixtures.get(revision)) => request('/__publish', {
    method: 'POST', body: JSON.stringify({ bundle, expectedRevision, ...options }) });
  const catalog = async () => (await (await request(`/content/v1/catalog/packs?topicId=${topicId}`)).json()).items;
  return { mf, db, bucket, request, publish, base, catalog, packId };
}
async function success(response) { assert.equal(response.status, 200, await response.clone().text()); return response; }

test('deterministic artifacts and Ed25519 receipts; unknown keys and tampering fail closed', async t => {
  const one = fixtures.get(1);
  assert.deepEqual(prepare(join(temporary, '1.biguesspack'), pem), one);
  assert(verify(null, Buffer.from(JSON.stringify(one.receipt.statement) + '\n'), publicKey, Buffer.from(one.receipt.signature, 'base64')));
  const { publish, db } = await setup(t);
  for (const mutate of [b => b.receipt.signature = Buffer.alloc(64).toString('base64'),
    b => b.receipt.keyId = '0'.repeat(64), b => b.manifest = Buffer.from('{}').toString('base64'),
    b => b.archive = Buffer.from('altered').toString('base64'),
    b => b.objects[Object.keys(b.objects)[0]] = Buffer.from('altered').toString('base64'),
    b => delete b.objects[Object.keys(b.objects)[0]]]) {
    const bundle = structuredClone(one); mutate(bundle);
    assert.equal((await publish(1, 0, {}, bundle)).status, 409);
    assert.equal((await db.prepare('SELECT count(*) AS n FROM publication_heads').first()).n, 0);
    assert.equal((await db.prepare('SELECT count(*) AS n FROM catalog_packs').first()).n, 0);
  }
});

test('anonymous full Pack resolve, receipt, manifest, archive and all objects match frozen contracts and signatures', async t => {
  const { publish, request, base, catalog } = await setup(t);
  await success(await publish(1, 0, { observeRevision: 0 }));
  const descriptorResponse = await success(await request(base + '/download'));
  const descriptor = await descriptorResponse.json(); validate('Download', descriptor);
  assert.equal((await catalog())[0].manifestSha256, descriptor.manifestSha256);
  const manifestResponse = await success(await request(new URL(descriptor.manifestUrl).pathname));
  const manifestBytes = Buffer.from(await manifestResponse.arrayBuffer());
  assert.equal(hash(manifestBytes), descriptor.manifestSha256);
  const manifest = JSON.parse(manifestBytes); validate('PublicManifest', manifest);
  const receipt = await (await request(base + '/revisions/1/signature')).json();
  assert(verify(null, Buffer.from(JSON.stringify(receipt.statement) + '\n'), publicKey, Buffer.from(receipt.signature, 'base64')));
  assert.equal(receipt.statement.manifestSha256, hash(manifestBytes));
  const archive = Buffer.from(await (await success(await request(new URL(descriptor.archiveUrl).pathname))).arrayBuffer());
  assert.equal(archive.length, descriptor.sizeBytes); assert.equal(hash(archive), descriptor.archiveSha256);
  // Re-run complete archive/image/provenance validation over the downloaded bytes.
  const { writeFileSync } = await import('node:fs');
  const downloaded = join(temporary, 'downloaded.biguesspack'); writeFileSync(downloaded, archive);
  assert.deepEqual(prepare(downloaded, pem), fixtures.get(1));
  for (const image of manifest.objects) {
    const response = await success(await request(new URL(image.key, descriptor.manifestUrl).pathname));
    const bytes = Buffer.from(await response.arrayBuffer());
    assert.equal(bytes.length, image.sizeBytes); assert.equal(hash(bytes), image.sha256);
    assert.equal(response.headers.get('Content-Type'), image.mediaType);
    assert.match(response.headers.get('Cache-Control'), /immutable/);
    assert.equal(response.headers.get('Access-Control-Allow-Origin'), '*');
  }
  assert.equal((await request(base + '/revisions/1/objects/' + '0'.repeat(64) + '.webp')).status, 404);
  assert.equal((await request('/objects/' + Object.keys(fixtures.get(1).objects)[0])).status, 404);
  assert.equal((await request(base + '/download', { method: 'POST' })).status, 400);
  assert.equal((await request(base + '/download', { method: 'OPTIONS' })).status, 204);
});

test('interrupted writes never expose a partial revision; CAS racing publishers have one winner; history survives rollback', async t => {
  const { publish, request, base, db, catalog } = await setup(t);
  await success(await publish(1, 0));
  for (const failAfter of [1, 2, 3, 4, 5, 6]) {
    assert.equal((await publish(2, 1, { failAfter, observeRevision: 1 })).status, 409);
    assert.equal((await catalog())[0].revision, 1);
    assert.equal((await request(base + '/revisions/2/manifest')).status, 404);
    assert.equal((await db.prepare('SELECT count(*) AS n FROM publication_revisions').first()).n, 1);
  }
  const results = await Promise.all([publish(2, 1), publish(3, 1)]);
  assert.deepEqual(results.map(r => r.status).sort(), [200, 409]);
  const current = (await catalog())[0].revision;
  const head = await db.prepare('SELECT * FROM publication_heads').first();
  assert.equal(head.revision, current); assert.equal(head.previous_revision, 1);
  assert.equal((await request(base + '/revisions/1/manifest')).status, 200);
  // Revision 4 exports the same original content, preserving monotonic revision identity.
  await success(await publish(4, current));
  assert.equal((await catalog())[0].revision, 4);
  assert.equal((await request(base + `/revisions/${current}/manifest`)).status, 200);
  assert.equal((await publish(1, 4)).status, 409);
  await assert.rejects(db.exec("DELETE FROM publication_revisions"), /immutable_publication/);
});

test('storage damage, unavailable parents and stale caches fail safely; existing immutable keys cannot be overwritten', async t => {
  const { publish, request, base, db, bucket } = await setup(t);
  await success(await publish(1, 0));
  const initial = await request(base + '/download'); const etag = initial.headers.get('ETag');
  assert.equal((await request(base + '/download', { headers: { 'If-None-Match': etag } })).status, 304);
  const s = fixtures.get(1).receipt.statement;
  const keys = [`manifests/${s.manifestSha256}.json`, `archives/${s.archiveSha256}.biguesspack`, ...Object.keys(fixtures.get(1).objects)];
  for (const key of keys) {
    const bytes = Buffer.from(await (await bucket.get(key)).arrayBuffer());
    for (const damage of ['missing', 'altered']) {
      if (damage === 'missing') await bucket.delete(key); else await bucket.put(key, 'bad');
      const response = await request(base + '/download', { headers: { 'If-None-Match': etag } });
      assert.equal(response.status, 503); assert.equal(response.headers.get('Cache-Control'), 'no-store');
      validate('Error', await response.json());
    }
    await bucket.put(key, bytes);
  }
  const imageKey = Object.keys(fixtures.get(1).objects)[0];
  await bucket.put(imageKey, 'corrupt immutable object');
  assert.equal((await publish(2, 1)).status, 409);
  assert.equal(await (await bucket.get(imageKey)).text(), 'corrupt immutable object');
  await bucket.put(imageKey, Buffer.from(fixtures.get(1).objects[imageKey], 'base64'));
  await db.exec('UPDATE catalog_topics SET published = 0');
  for (const suffix of ['/download', '/revisions/1/manifest', '/revisions/1/archive.biguesspack']) {
    assert.equal((await request(base + suffix, { headers: { 'If-None-Match': '*' } })).status, 403);
  }
  await db.exec('UPDATE catalog_topics SET deleted = 1');
  assert.equal((await request(base + '/download')).status, 410);
});

test('D1 projection failure rolls back activation and history; a retry uses the same immutable artifacts', async t => {
  const { publish, request, base, db, catalog } = await setup(t);
  await success(await publish(1, 0));
  await db.exec("CREATE TRIGGER reject_projection BEFORE UPDATE ON catalog_packs BEGIN SELECT RAISE(ABORT, 'injected_projection_failure'); END;");
  assert.equal((await publish(2, 1)).status, 409);
  assert.equal((await catalog())[0].revision, 1);
  assert.equal((await db.prepare('SELECT revision FROM publication_heads').first()).revision, 1);
  assert.equal((await db.prepare('SELECT count(*) AS n FROM publication_revisions').first()).n, 1);
  assert.equal((await request(base + '/revisions/2/manifest')).status, 404);
  await db.exec('DROP TRIGGER reject_projection');
  await success(await publish(2, 1));
  assert.equal((await catalog())[0].revision, 2);
});


test('signed but invalid product, rights, schema and image data never activate a revision', async t => {
  const { publish, db } = await setup(t);
  const edits = [
    m => m.cards[0].difficulty = 4,
    m => m.cards[0].packId = 'other-pack',
    m => m.cards[0].name = ' Untrimmed ',
    m => m.cards[0].description = 'Unapproved semantic field',
    m => m.cards = m.cards.slice(0, 1),
    m => m.cards[1].id = m.cards[0].id,
    m => m.provenance.packRights.permission_to_publish = false,
    m => m.provenance.cardRights.pop(),
    m => m.provenance.cardRights[0].public_test_publishable = false,
    m => m.objects.push(m.objects[0]),
    m => m.objects[0].mediaType = ['image/webp'],
    (m, b) => {
      const old = m.objects[0]; const bytes = Buffer.from('signed non-image');
      const sha256 = hash(bytes); const key = `objects/${sha256}.webp`;
      delete b.objects[old.key]; b.objects[key] = bytes.toString('base64');
      for (const c of m.cards) if (c.imageReference === old.key) c.imageReference = key;
      m.objects[0] = { key, sha256, sizeBytes: bytes.length, mediaType: 'image/webp' };
      m.objects.sort((a, b) => a.key.localeCompare(b.key));
    },
  ];
  for (const edit of edits) {
    assert.equal((await publish(1, 0, {}, rewrite(fixtures.get(1), edit))).status, 409);
    assert.equal(await db.prepare('SELECT count(*) AS n FROM publication_heads').first('n'), 0);
    assert.equal(await db.prepare('SELECT count(*) AS n FROM studio_entities').first('n'), 0);
  }
});

test('publication hydrates authoring records and cannot overwrite a newer draft or deletion', async t => {
  const { publish, db, packId, catalog } = await setup(t);
  await success(await publish(1, 0));
  const pack = await db.prepare("SELECT * FROM studio_entities WHERE resource_type = 'pack' AND id = ?").bind(packId).first();
  assert.equal(pack.revision, 1);
  assert.equal(await db.prepare("SELECT count(*) AS n FROM studio_entities WHERE resource_type = 'card'").first('n'), 4);
  const value = { ...JSON.parse(pack.value), name: 'Reviewed Shapes' };
  await db.prepare("UPDATE studio_entities SET value = ?, revision = 2 WHERE resource_type = 'pack' AND id = ?")
    .bind(JSON.stringify(value), packId).run();
  await db.exec('UPDATE studio_generation SET generation = generation + 1');
  await db.prepare('INSERT INTO publication_suppression VALUES (?, 1)').bind(packId).run();
  await db.exec('UPDATE catalog_packs SET published = 0');
  assert.equal((await publish(3, 1)).status, 409, 'cannot leap over a pending draft revision');
  assert.equal((await publish(2, 1)).status, 409, 'same revision must match the draft content');
  assert.deepEqual(await catalog(), []);
  assert.equal(await db.prepare('SELECT resume_published FROM publication_suppression WHERE pack_id = ?').bind(packId).first('resume_published'), 1);
  const fixtureDirectory = join(temporary, 'reviewed-fixture');
  cpSync(new URL('../../../test/fixtures/cleared_shapes', import.meta.url), fixtureDirectory, { recursive: true });
  const path = join(fixtureDirectory, 'pack.json'); const fixture = JSON.parse(readFileSync(path));
  fixture.pack.name = 'Reviewed Shapes'; writeFileSync(path, JSON.stringify(fixture));
  const bundleAt = revision => {
    const archive = join(temporary, `reviewed-${revision}.biguesspack`);
    execFileSync('python3', ['../../scripts/export_pack.py', 'fixture', path, '--revision', String(revision), '--output', archive], { cwd: root });
    return prepare(archive, pem);
  };
  await success(await publish(2, 1, {}, bundleAt(2)));
  assert.equal((await catalog())[0].name, 'Reviewed Shapes');
  await db.prepare("UPDATE studio_entities SET state = 'deleted', revision = 3 WHERE resource_type = 'pack' AND id = ?").bind(packId).run();
  await db.prepare("INSERT INTO studio_tombstones VALUES ('pack', ?, 3, '2026-11-07T00:00:00Z')").bind(packId).run();
  await db.exec('UPDATE studio_generation SET generation = generation + 1');
  assert.equal((await publish(4, 2, {}, bundleAt(4))).status, 409, 'publication never restores deleted content');
  assert.equal((await catalog())[0].revision, 2);
  assert.equal(await db.prepare('SELECT revision FROM publication_heads').first('revision'), 2);
});


test('publication and administrative commits share a generation guard with atomic rollback', async t => {
  const { publish, db, packId } = await setup(t);
  const before = await db.prepare('SELECT generation FROM studio_generation').first('generation');
  await success(await publish(1, 0));
  const published = await db.prepare('SELECT generation FROM studio_generation').first('generation');
  assert.equal(published, before + 1);
  // An administrative validation begun before the publication cannot commit.
  await assert.rejects(db.prepare('INSERT INTO studio_commits VALUES (?, ?, ?, ?, ?, ?, ?)')
    .bind('owner', 'stale-admin', 'fingerprint', '[]', '{}', 'stale-admin', before).run(), /studio_conflict/);
  await db.exec('UPDATE studio_generation SET generation = generation + 1');
  // A publication validation begun before an administrative commit cannot commit
  // either; its dependent projection writes roll back with the guard failure.
  await assert.rejects(db.batch([
    db.prepare('INSERT INTO publication_commits VALUES (?, 2, ?)').bind(packId, published),
    db.prepare("UPDATE catalog_packs SET name = 'Lost update' WHERE id = ?").bind(packId),
  ]), /publication_conflict/);
  assert.equal(await db.prepare('SELECT revision FROM publication_heads').first('revision'), 1);
  assert.equal(await db.prepare('SELECT count(*) AS n FROM publication_commits').first('n'), 1);
  assert.notEqual(await db.prepare('SELECT name FROM catalog_packs').first('name'), 'Lost update');
});

import assert from 'node:assert/strict';
import { test } from 'node:test';
import { readFileSync, writeFileSync, readdirSync, mkdtempSync, rmSync, cpSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { execFileSync } from 'node:child_process';
import { createHash, generateKeyPairSync, randomUUID } from 'node:crypto';
import { generateKeyPair, exportJWK, SignJWT } from 'jose';
import { Miniflare, convertV4MiniflareOptions } from 'miniflare';
import { root } from '../scripts/local.mjs';
import { prepare } from '../scripts/prepare.mjs';

const hash = bytes => createHash('sha256').update(bytes).digest('hex');
const { privateKey } = generateKeyPairSync('ed25519');
const pem = privateKey.export({ type: 'pkcs8', format: 'pem' });
const temporary = mkdtempSync(join(tmpdir(), 'biguess-sync-delta-'));
process.on('exit', () => rmSync(temporary, { recursive: true, force: true }));
const fixtureRoot = join(temporary, 'fixture');
cpSync(new URL('../../../test/fixtures/cleared_shapes/', import.meta.url), fixtureRoot, { recursive: true });
execFileSync('python3', ['-c', 'from PIL import Image; import sys; Image.new("RGB", (16,16), (11,94,147)).save(sys.argv[1], format="WEBP", lossless=True)', join(fixtureRoot, 'Replacement.webp')]);
const source = JSON.parse(readFileSync(join(fixtureRoot, 'pack.json')));
const packId = source.pack.id;
const topicId = source.topic.id;
const addedCardId = 'card:added-shape';
const editedCardId = source.cards[0].id;
const hiddenCardId = source.cards[1].id;
const secondPackId = 'pack:second-shapes';
const fixtures = new Map();
function exportFixture(label, revision, value) {
  const path = join(fixtureRoot, `${label}.json`); writeFileSync(path, JSON.stringify(value));
  const archive = join(temporary, `${label}.biguesspack`);
  execFileSync('python3', ['../../scripts/export_pack.py', 'fixture', path, '--revision', String(revision), '--output', archive],
    { cwd: root, stdio: 'pipe' });
  return prepare(archive, pem);
}
for (let revision = 1; revision <= 6; revision++) {
  if (revision === 3) source.cards.push({ ...source.cards[0], id: addedCardId, name: 'Additional Circle' });
  if (revision === 4) Object.assign(source.cards.find(c => c.id === editedCardId), { name: 'Edited Circle', difficulty: 3 });
  if (revision === 5) source.cards.find(c => c.id === editedCardId).image = 'Replacement.webp';
  if (revision === 6) source.cards = source.cards.filter(c => c.id !== hiddenCardId);
  fixtures.set(revision, exportFixture(`revision-${revision}`, revision, source));
}
const second = structuredClone(JSON.parse(readFileSync(join(fixtureRoot, 'pack.json'))));
second.pack.id = secondPackId;
second.pack.name = 'Other Shapes';
second.cards = second.cards.map(c => ({ ...c, id: `second:${c.id}`, pack_id: secondPackId }));
fixtures.set('second', exportFixture('second', 1, second));
fixtures.set('restored', exportFixture('restored', 5, JSON.parse(readFileSync(join(fixtureRoot, 'pack.json')))));
const manifests = new Map([...fixtures].map(([revision, bundle]) => [revision,
  JSON.parse(Buffer.from(bundle.manifest, 'base64'))]));
execFileSync(process.execPath, ['node_modules/wrangler/bin/wrangler.js', 'deploy', 'test/publication-worker.ts',
  '--env', 'staging', '--dry-run', '--outdir', join(temporary, 'worker')], { cwd: root, stdio: 'pipe' });

const project = 'biguess-sync-test';
const identityKeys = await generateKeyPair('RS256');
const jwk = { ...await exportJWK(identityKeys.publicKey), kid: 'google-sync-test', alg: 'RS256', use: 'sig' };
const users = ['owner', 'collector'].map(uid => ({ uid, email: `${uid}@example.test`,
  role: uid === 'owner' ? 'owner_admin' : 'collector' }));
function validate(kind, payload) {
  execFileSync('python3', ['-c', 'import json,sys; sys.path.insert(0,"../../scripts"); from validate_content_contract import validate; validate(sys.argv[1],json.load(sys.stdin))', kind],
    { cwd: root, input: JSON.stringify(payload), stdio: 'pipe' });
}
async function setup(t) {
  const tokens = {};
  for (const { uid, email } of users) {
    const now = Math.floor(Date.now() / 1000);
    tokens[uid] = await new SignJWT({ sub: uid, email, email_verified: true, firebase: { sign_in_provider: 'google.com' },
      aud: project, iss: `https://securetoken.google.com/${project}`, iat: now - 10, auth_time: now - 20, exp: now + 3600 })
      .setProtectedHeader({ alg: 'RS256', kid: jwk.kid }).sign(identityKeys.privateKey);
  }
  const mf = new Miniflare(convertV4MiniflareOptions({ modules: true,
    modulesRoot: join(temporary, 'worker'), scriptPath: join(temporary, 'worker/publication-worker.js'), compatibilityDate: '2026-11-01',
    bindings: { APP_ENV: 'staging', PUBLICATION_KEYS: JSON.stringify(fixtures.get(1).trustedKeys),
      FIREBASE_PROJECT_ID: project, STUDIO_USERS: JSON.stringify(users) },
    d1Databases: { DB: 'sync-delta-test' }, r2Buckets: { CONTENT: 'sync-delta-test' },
    outboundService: request => {
      assert.equal(request.url, 'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com');
      return Response.json({ keys: [jwk] });
    },
  }));
  t.after(() => mf.dispose());
  const db = await mf.getD1Database('DB');
  for (const file of readdirSync(`${root}migrations`).filter(file => file.endsWith('.sql')).sort()) {
    await db.exec(readFileSync(`${root}migrations/${file}`, 'utf8').split('\n')
      .filter(line => !line.trim().startsWith('--')).join(' '));
  }
  const bucket = await mf.getR2Bucket('CONTENT');
  const request = (path, options) => mf.dispatchFetch(`https://content.example${path}`, options);
  const publish = (revision, expectedRevision, bundle = fixtures.get(revision)) => request('/__publish', {
    method: 'POST', body: JSON.stringify({ bundle, expectedRevision }) });
  const known = (revision = 1, id = packId) => ({ packId: id, revision });
  const sync = (packs, options = {}) => request('/content/v1/sync/revisions', {
    method: 'POST', body: JSON.stringify({ protocolVersion: 1, packs }), ...options });
  const delta = (from, to, options = {}) => request(`/content/v1/packs/${encodeURIComponent(packId)}/delta?fromRevision=${from}&toRevision=${to}`, options);
  const commit = (resourceType, id, operations, revision, actor = 'owner') => request('/studio/v1/batches', {
    method: 'POST', headers: { Authorization: `Bearer ${tokens[actor]}`, 'Idempotency-Key': randomUUID(), 'If-Match': `"rev-${revision}"` },
    body: JSON.stringify({ protocolVersion: 1, aggregate: { resourceType, id }, operations }),
  });
  const action = (resourceType, id, name) => ({ resourceType, id, action: name });
  async function publishThrough(revision) {
    for (let i = 1; i <= revision; i++) await success(await publish(i, i - 1));
  }
  return { db, bucket, request, publish, known, sync, delta, commit, action, publishThrough };
}
async function success(response) {
  assert.equal(response.status, 200, await response.clone().text());
  return response;
}
async function error(response, status, code) {
  assert.equal(response.status, status, await response.clone().text());
  assert.equal(response.headers.get('Cache-Control'), 'no-store');
  const body = await response.json(); validate('Error', body);
  assert.equal(body.error.code, code);
  return body.error;
}
async function syncBody(response) {
  await success(response);
  assert.equal(response.headers.get('Cache-Control'), 'no-store');
  assert.equal(response.headers.get('Access-Control-Allow-Origin'), '*');
  const body = await response.json(); validate('RevisionResponse', body);
  return body;
}
async function deltaBody(response) {
  await success(response);
  assert.equal(response.headers.get('Cache-Control'), 'public, max-age=60, must-revalidate');
  assert.equal(response.headers.get('Access-Control-Allow-Origin'), '*');
  const raw = await response.text();
  assert.equal(response.headers.get('ETag'), `"${hash(Buffer.from(raw))}"`);
  const body = JSON.parse(raw); validate('Delta', body);
  return body;
}

test('anonymous revision checks distinguish unchanged, updates and unknown IDs with exactly one result per request', async t => {
  const { publishThrough, sync, known } = await setup(t); await publishThrough(2);
  const same = (await syncBody(await sync([known(2)]))).results[0];
  assert.deepEqual(same, { packId, status: 'unchanged', revision: 2,
    manifestSha256: fixtures.get(2).receipt.statement.manifestSha256 });
  const results = (await syncBody(await sync([known(1), known(1, 'pack:never-known')]))).results;
  assert.deepEqual(results, [
    { packId, status: 'updateAvailable', revision: 2, manifestSha256: fixtures.get(2).receipt.statement.manifestSha256 },
    { packId: 'pack:never-known', status: 'unknown' },
  ]);
  await error(await sync([known(3)]), 409, 'revision_conflict');
});

test('revision request validation is bounded, strict and anonymous CORS supports POST preflight', async t => {
  const { request, known, sync } = await setup(t);
  for (const packs of [[], [known(), known()], Array.from({ length: 101 }, (_, i) => known(1, `pack:${i}`)),
    [{ packId, revision: 0 }], [{ packId, revision: 1.5 }], [{ packId, revision: '1' }],
    [{ packId, revision: 1, manifestSha256: 'a'.repeat(64) }], [{ packId: ' bad ', revision: 1 }]]) {
    await error(await sync(packs), 400, 'invalid_request');
  }
  const full = Array.from({ length: 100 }, (_, i) => known(1, `pack:${i}`));
  const body = await syncBody(await sync(full));
  assert.equal(body.results.length, 100);
  assert.ok(body.results.every(row => row.status === 'unknown'));
  await error(await request('/content/v1/sync/revisions', { method: 'POST', body: 'not json' }), 400, 'invalid_request');
  await error(await request('/content/v1/sync/revisions', { method: 'GET' }), 400, 'invalid_request');
  const preflight = await request('/content/v1/sync/revisions', { method: 'OPTIONS', headers: {
    Origin: 'https://mobile.example', 'Access-Control-Request-Method': 'POST', 'Access-Control-Request-Headers': 'Content-Type' } });
  assert.equal(preflight.status, 204);
  assert.match(preflight.headers.get('Access-Control-Allow-Methods'), /POST/);
  assert.match(preflight.headers.get('Access-Control-Allow-Headers'), /Content-Type/i);
});

test('metadata-only publication produces an empty delta and skips all image transfer', async t => {
  const { publishThrough, delta } = await setup(t); await publishThrough(2);
  const change = await deltaBody(await delta(1, 2));
  assert.equal(change.packId, packId);
  assert.deepEqual(change.upsertCards, []);
  assert.deepEqual(change.removeCardIds, []);
  assert.deepEqual(change.objects, []);
  assert.equal(change.targetManifestSha256, fixtures.get(2).receipt.statement.manifestSha256);
  assert.equal(change.targetManifestUrl, `https://content.example/content/v1/packs/${packId}/revisions/2/manifest`);
});

test('added and edited Cards carry complete metadata but reuse unchanged content-addressed images', async t => {
  const { publishThrough, delta } = await setup(t); await publishThrough(4);
  const added = await deltaBody(await delta(2, 3));
  assert.deepEqual(added.upsertCards.map(c => c.id), [addedCardId]);
  assert.deepEqual(added.objects, []);
  assert.deepEqual(added.removeCardIds, []);
  const edited = await deltaBody(await delta(3, 4));
  assert.deepEqual(edited.upsertCards, [manifests.get(4).cards.find(c => c.id === editedCardId)]);
  assert.equal(edited.upsertCards[0].name, 'Edited Circle');
  assert.equal(edited.upsertCards[0].difficulty, 3);
  assert.deepEqual(edited.objects, []);
  assert.deepEqual(edited.removeCardIds, []);
});

test('image replacements list only new required bytes and multi-revision deltas reconstruct the exact target', async t => {
  const { publishThrough, delta, request } = await setup(t); await publishThrough(6);
  const changed = await deltaBody(await delta(4, 5));
  assert.deepEqual(changed.upsertCards.map(c => c.id), [editedCardId]);
  assert.equal(changed.objects.length, 1);
  const originalKeys = new Set(manifests.get(4).objects.map(o => o.key));
  assert.ok(changed.objects.every(o => !originalKeys.has(o.key)));
  assert.deepEqual(changed.objects.map(o => o.key), changed.upsertCards.map(c => c.imageReference));
  for (const object of changed.objects) {
    const response = await success(await request(new URL(object.key, changed.targetManifestUrl).pathname));
    const bytes = Buffer.from(await response.arrayBuffer());
    assert.equal(hash(bytes), object.sha256);
    assert.equal(bytes.length, object.sizeBytes);
  }
  const all = await deltaBody(await delta(1, 6));
  const merged = new Map(manifests.get(1).cards.map(c => [c.id, c]));
  for (const id of all.removeCardIds) merged.delete(id);
  for (const card of all.upsertCards) merged.set(card.id, card);
  assert.deepEqual([...merged.values()].sort((a, b) => a.id.localeCompare(b.id)),
    [...manifests.get(6).cards].sort((a, b) => a.id.localeCompare(b.id)));
  assert.deepEqual(all.removeCardIds, [hiddenCardId]);
  assert.equal(all.objects.length, 1);
  const required = new Set([...merged.values()].map(c => c.imageReference));
  const retained = [...manifests.get(1).objects, ...all.objects].filter(o => required.has(o.key));
  assert.deepEqual(retained.sort((a, b) => a.key.localeCompare(b.key)),
    [...manifests.get(6).objects].sort((a, b) => a.key.localeCompare(b.key)));
});

test('hidden or removed Cards are removals without tombstones or unchanged object bytes in the delta', async t => {
  const { publishThrough, publish, commit, action, delta, db, sync, known, request } = await setup(t); await publishThrough(5);
  await success(await commit('pack', packId, [action('card', hiddenCardId, 'hide')], 5, 'collector'));
  assert.deepEqual((await syncBody(await sync([known(5)]))).results, [{ packId, status: 'unavailable' }]);
  await success(await publish(6, 5));
  const hidden = await deltaBody(await delta(5, 6));
  assert.deepEqual(hidden.upsertCards, []);
  assert.deepEqual(hidden.removeCardIds, [hiddenCardId]);
  assert.deepEqual(hidden.objects, []);
  assert.equal((await syncBody(await sync([known(5)]))).results[0].status, 'updateAvailable');
  assert.equal((await request(`/content/v1/packs/${packId}/download`)).status, 200);
  assert.equal(await db.prepare('SELECT count(*) AS n FROM studio_tombstones').first('n'), 0);
});

test('delta request validation rejects bad ranges and returns an explicit full-download fallback for missing history', async t => {
  const { publishThrough, delta, request } = await setup(t); await publishThrough(2);
  for (const [from, to] of [[1, 1], [2, 1], [0, 2], ['01', 2], ['1.0', 2], [1, '9007199254740992']]) {
    await error(await delta(from, to), 400, 'invalid_request');
  }
  const path = `/content/v1/packs/${packId}/delta`;
  for (const query of ['', '?fromRevision=1', '?fromRevision=1&toRevision=2&x=1', '?fromRevision=1&fromRevision=1&toRevision=2']) {
    await error(await request(path + query), 400, 'invalid_request');
  }
  await error(await delta(1, 9), 409, 'delta_unavailable');
  await error(await request('/content/v1/packs/never-known/delta?fromRevision=1&toRevision=2'), 404, 'not_found');
});

test('delta ETags revalidate exact bytes only after visibility and stored-artifact checks', async t => {
  const { publishThrough, delta, db, bucket, sync, known } = await setup(t); await publishThrough(2);
  const first = await success(await delta(1, 2));
  const etag = first.headers.get('ETag');
  assert.equal((await delta(1, 2, { headers: { 'If-None-Match': etag } })).status, 304);
  const imageKey = manifests.get(2).objects[0].key;
  const image = Buffer.from(await (await bucket.get(imageKey)).arrayBuffer());
  await bucket.delete(imageKey);
  // Lightweight discovery reads signed revision metadata without fetching image bytes.
  assert.equal((await syncBody(await sync([known(2)]))).results[0].status, 'unchanged');
  await error(await delta(1, 2, { headers: { 'If-None-Match': etag } }), 503, 'internal_error');
  await bucket.put(imageKey, image, { httpMetadata: { contentType: manifests.get(2).objects[0].mediaType } });
  await db.exec('UPDATE catalog_packs SET published = 0');
  await error(await delta(1, 2, { headers: { 'If-None-Match': etag } }), 403, 'unavailable');
  await db.exec('UPDATE catalog_packs SET deleted = 1');
  await error(await delta(1, 2, { headers: { 'If-None-Match': etag } }), 410, 'deleted');
});

test('hiding never grants deletion authority and parent visibility applies to revision checks', async t => {
  const { publishThrough, commit, action, sync, known, db } = await setup(t); await publishThrough(1);
  await success(await commit('pack', packId, [action('pack', packId, 'hide')], 1, 'collector'));
  assert.deepEqual((await syncBody(await sync([known()]))).results, [{ packId, status: 'unavailable' }]);
  assert.equal(await db.prepare('SELECT count(*) AS n FROM studio_tombstones').first('n'), 0);
  await db.exec('UPDATE catalog_packs SET published = 1');
  await db.exec('UPDATE catalog_topics SET published = 0');
  assert.deepEqual((await syncBody(await sync([known()]))).results, [{ packId, status: 'unavailable' }]);
});

test('Owner tombstones remain discoverable after catalog removal and permanent content purge', async t => {
  const { publishThrough, commit, action, sync, known, db } = await setup(t); await publishThrough(1);
  await success(await commit('pack', packId, [action('pack', packId, 'softDelete')], 1));
  const first = (await syncBody(await sync([known()]))).results[0];
  assert.equal(first.status, 'deleted');
  assert.deepEqual(first.tombstone, { packId, revision: 2, deletedAt: first.tombstone.deletedAt,
    reason: 'administrative_deletion' });
  assert.ok(Number.isFinite(Date.parse(first.tombstone.deletedAt)));
  await db.prepare('DELETE FROM catalog_packs WHERE id = ?').bind(packId).run();
  assert.deepEqual((await syncBody(await sync([known()]))).results[0], first);
  await success(await commit('pack', packId, manifests.get(1).cards.map(c => action('card', c.id, 'permanentDelete')), 2));
  await success(await commit('pack', packId, [action('pack', packId, 'permanentDelete')], 3));
  assert.deepEqual((await syncBody(await sync([known()]))).results[0], first);
  await error(await sync([known(2)]), 409, 'revision_conflict');
  const fence = await db.prepare("SELECT * FROM studio_entities WHERE resource_type = 'pack' AND id = ?").bind(packId).first();
  assert.equal(fence.state, 'purged');
  assert.equal(fence.value, null);
});

test('restoration retains older deletion evidence and never implicitly republishes a Pack', async t => {
  const { publishThrough, publish, commit, action, sync, known, db } = await setup(t); await publishThrough(1);
  await success(await commit('pack', packId, [action('pack', packId, 'softDelete')], 1));
  const deleted = (await syncBody(await sync([known()]))).results[0];
  await success(await commit('pack', packId, [action('pack', packId, 'restore')], 2));
  assert.deepEqual((await syncBody(await sync([known()]))).results[0], deleted);
  assert.deepEqual((await syncBody(await sync([known(2)]))).results, [{ packId, status: 'unavailable' }]);
  await success(await commit('pack', packId, manifests.get(1).cards.map(c => action('card', c.id, 'restore')), 3));
  await success(await commit('pack', packId, manifests.get(1).cards.map(c => action('card', c.id, 'activate')), 4));
  await success(await publish('restored', 1));
  // Simulate the separate T35 Owner approval after validating the restored snapshot.
  await db.prepare('UPDATE catalog_packs SET published = 1 WHERE id = ?').bind(packId).run();
  await db.prepare("UPDATE studio_entities SET state = 'active' WHERE resource_type = 'pack' AND id = ?").bind(packId).run();
  assert.deepEqual((await syncBody(await sync([known()]))).results[0], deleted);
  assert.deepEqual((await syncBody(await sync([known(5)]))).results, [{ packId, status: 'unchanged', revision: 5,
    manifestSha256: fixtures.get('restored').receipt.statement.manifestSha256 }]);
});

test('Topic deletion emits durable newer tombstones for each installed descendant Pack', async t => {
  const { publishThrough, publish, commit, action, sync, known, db } = await setup(t); await publishThrough(1);
  await success(await publish('second', 0));
  await success(await commit('topic', topicId, [action('topic', topicId, 'softDelete')], 1));
  await db.exec('DELETE FROM catalog_packs');
  const results = (await syncBody(await sync([known(), known(1, secondPackId)]))).results;
  assert.equal(results.length, 2);
  for (const result of results) {
    assert.equal(result.status, 'deleted');
    assert.equal(result.tombstone.packId, result.packId);
    assert.equal(result.tombstone.revision, 2);
  }
});

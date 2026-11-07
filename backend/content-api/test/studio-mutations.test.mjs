import assert from 'node:assert/strict';
import { test } from 'node:test';
import { readFileSync, readdirSync } from 'node:fs';
import { createHash, randomUUID } from 'node:crypto';
import { generateKeyPair, exportJWK, SignJWT } from 'jose';
import { Miniflare, convertV4MiniflareOptions } from 'miniflare';
import { root } from '../scripts/local.mjs';

// Exercise deployed routing, Firebase verification, D1 transactions and R2 reads.
// Only Google's public-key response is substituted; no application auth bypass.
const project = 'biguess-mutations-test';
const keys = await generateKeyPair('RS256');
const jwk = { ...await exportJWK(keys.publicKey), kid: 'google-mutation-test', alg: 'RS256', use: 'sig' };
const users = ['owner', 'collector'].map(uid => ({ uid, email: `${uid}@example.test`,
  role: uid === 'owner' ? 'owner_admin' : 'collector' }));
const image = readFileSync(new URL('../fixtures/image.webp', import.meta.url));
const imageReference = `objects/${createHash('sha256').update(image).digest('hex')}.webp`;
const op = (resourceType, id, action, value) => ({ resourceType, id, action,
  ...(value === undefined ? {} : { value }) });
const topic = (id = 'topic') => op('topic', id, 'create', { name: `Topic ${id}` });
const pack = (id = 'pack', topicId = 'topic') => op('pack', id, 'create', { name: `Pack ${id}`, topicId });
const card = (id = 'card', packId = 'pack') => op('card', id, 'create', {
  packId, name: `Card ${id}`, imageReference, difficulty: 1 });

async function setup(t) {
  const tokens = {};
  for (const { uid, email } of users) {
    const now = Math.floor(Date.now() / 1000);
    tokens[uid] = await new SignJWT({ sub: uid, email, email_verified: true,
      firebase: { sign_in_provider: 'google.com' }, aud: project,
      iss: `https://securetoken.google.com/${project}`, iat: now - 10,
      auth_time: now - 20, exp: now + 3600 })
      .setProtectedHeader({ alg: 'RS256', kid: jwk.kid }).sign(keys.privateKey);
  }
  const mf = new Miniflare(convertV4MiniflareOptions({ modules: true,
    scriptPath: `${root}dist/index.js`, compatibilityDate: '2026-11-01',
    bindings: { APP_ENV: 'staging', FIREBASE_PROJECT_ID: project, STUDIO_USERS: JSON.stringify(users) },
    d1Databases: { DB: 'studio-mutations-test' }, r2Buckets: { CONTENT: 'studio-images-test' },
    outboundService: request => {
      assert.equal(request.url, 'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com');
      return Response.json({ keys: [jwk] });
    },
  }));
  t.after(() => mf.dispose());
  const db = await mf.getD1Database('DB');
  for (const file of readdirSync(`${root}migrations`).filter(file => file.endsWith('.sql')).sort()) {
    await db.exec(readFileSync(`${root}migrations/${file}`, 'utf8')
      .split('\n').filter(line => !line.trim().startsWith('--')).join(' '));
  }
  const bucket = await mf.getR2Bucket('CONTENT');
  await bucket.put(imageReference, image, { httpMetadata: { contentType: 'image/webp' } });
  const send = (body, revision, { actor = 'owner', key = randomUUID(), headers = {},
    path = '/studio/v1/batches', method = 'POST' } = {}) => mf.dispatchFetch(`https://api.example${path}`, {
    method, headers: { Authorization: `Bearer ${tokens[actor]}`, 'Content-Type': 'application/json',
      'Idempotency-Key': key, ...(revision === 0 ? { 'If-None-Match': '*' }
        : revision === undefined ? {} : { 'If-Match': `"rev-${revision}"` }), ...headers },
    body: JSON.stringify(body),
  });
  const commit = (resourceType, id, operations, revision, options) => send({ protocolVersion: 1,
    aggregate: { resourceType, id }, operations }, revision, options);
  const row = (resourceType, id) => db.prepare(
    'SELECT * FROM studio_entities WHERE resource_type = ? AND id = ?').bind(resourceType, id).first();
  const count = table => db.prepare(`SELECT count(*) AS n FROM ${table}`).first('n');
  async function seed() {
    await success(await commit('topic', 'topic', [topic()], 0), 1);
    await success(await commit('pack', 'pack', [pack(), card('a'), card('b')], 0, { actor: 'collector' }), 1);
  }
  const get = path => mf.dispatchFetch(`https://api.example${path}`);
  return { db, bucket, send, commit, row, count, seed, get };
}
async function success(response, revision) {
  assert.equal(response.status, 200, await response.clone().text());
  assert.equal(response.headers.get('Cache-Control'), 'no-store');
  assert.equal(response.headers.get('ETag'), `"rev-${revision}"`);
  const body = await response.json();
  assert.equal(body.protocolVersion, 1);
  assert.equal(body.revision, revision);
  assert.equal(typeof body.actorId, 'string');
  assert.ok(Number.isFinite(Date.parse(body.committedAt)));
  return body;
}
async function failure(response, status, code) {
  assert.equal(response.status, status, await response.clone().text());
  assert.equal(response.headers.get('Cache-Control'), 'no-store');
  const body = await response.json();
  assert.equal(body.protocolVersion, 1);
  assert.equal(body.error.code, code);
  assert.equal(body.error.retryable, status === 503);
  return body.error;
}

test('Collector creates and edits a whole Pack batch; one aggregate revision and server audit attribution', async t => {
  const { commit, row, db, seed } = await setup(t); await seed();
  const result = await success(await commit('pack', 'pack', [
    op('pack', 'pack', 'update', { name: 'Renamed', topicId: 'topic' }),
    op('card', 'a', 'update', { ...card('a').value, name: 'New name', difficulty: 3 }),
    op('card', 'b', 'hide'),
  ], 1, { actor: 'collector', path: '/content/v1/studio/batches' }), 2);
  assert.equal(result.actorId, 'collector');
  assert.equal((await row('pack', 'pack')).revision, 2);
  assert.equal(JSON.parse((await row('card', 'a')).value).name, 'New name');
  assert.equal((await row('card', 'b')).state, 'hidden');
  const audit = (await db.prepare('SELECT * FROM studio_audit WHERE revision = 2').all()).results;
  assert.equal(audit.length, 3);
  assert.ok(audit.every(a => a.actor_id === 'collector' && a.actor_role === 'collector'));
  assert.equal(new Set(audit.map(a => a.batch_id)).size, 1);
  await success(await commit('pack', 'pack', [op('card', 'b', 'activate')], 2, { actor: 'collector' }), 3);
  assert.equal((await row('card', 'b')).state, 'active');
});

test('stale and competing commits reject clearly and never lose the winning edit', async t => {
  const { commit, row, count, seed } = await setup(t); await seed();
  const before = await count('studio_audit');
  const update = name => commit('pack', 'pack', [op('pack', 'pack', 'update', { name, topicId: 'topic' })], 1);
  const replies = await Promise.all([update('One'), update('Two')]);
  assert.deepEqual(replies.map(r => r.status).sort(), [200, 412]);
  const loser = replies.find(r => r.status === 412);
  assert.equal((await failure(loser, 412, 'revision_conflict')).currentRevision, 2);
  assert.ok(['One', 'Two'].includes(JSON.parse((await row('pack', 'pack')).value).name));
  assert.equal(await count('studio_audit'), before + 1);
  assert.equal((await failure(await update('Stale'), 412, 'revision_conflict')).currentRevision, 2);
});

test('idempotent retries return original result while changed payload or precondition conflicts', async t => {
  const { commit, send, count } = await setup(t); const key = 'owner-topic-create';
  const first = await success(await commit('topic', 'topic', [topic()], 0, { key }), 1);
  const retry = await success(await commit('topic', 'topic', [topic()], 0, { key }), 1);
  assert.deepEqual(retry, first);
  const reordered = await success(await send({ operations: [{ value: { name: 'Topic topic' },
    action: 'create', id: 'topic', resourceType: 'topic' }],
    aggregate: { id: 'topic', resourceType: 'topic' }, protocolVersion: 1 }, 0, { key }), 1);
  assert.deepEqual(reordered, first);
  assert.equal(await count('studio_audit'), 1);
  await failure(await commit('topic', 'topic', [topic('other')], 0, { key }), 409, 'idempotency_conflict');
  await failure(await commit('topic', 'topic', [topic()], 1, { key }), 409, 'idempotency_conflict');
  await failure(await commit('topic', 'topic', [topic()], 0), 412, 'revision_conflict');
});

test('every operation is authorized before writing; Collectors cannot smuggle deletion, restore or Topic edits', async t => {
  const { commit, row, count, seed } = await setup(t); await seed();
  const before = await count('studio_audit');
  for (const action of ['softDelete', 'restore', 'permanentDelete']) {
    await failure(await commit('pack', 'pack', [op('card', 'a', 'hide'), op('card', 'b', action)], 1,
      { actor: 'collector' }), 403, 'forbidden');
    await failure(await commit('pack', 'pack', [op('pack', 'pack', action)], 1,
      { actor: 'collector' }), 403, 'forbidden');
    await failure(await commit('topic', 'topic', [op('topic', 'topic', action)], 1,
      { actor: 'collector' }), 403, 'forbidden');
  }
  await failure(await commit('topic', 'topic', [op('topic', 'topic', 'update', { name: 'Stolen' })], 1,
    { actor: 'collector' }), 403, 'forbidden');
  assert.equal((await row('card', 'a')).state, 'active');
  assert.equal((await row('pack', 'pack')).revision, 1);
  assert.equal(await count('studio_audit'), before);
  assert.equal(await count('studio_tombstones'), 0);
});

test('strict fields, duplicate IDs, malformed preconditions and invalid images leave no partial batch', async t => {
  const { commit, send, count, row, seed, bucket } = await setup(t); await seed();
  const before = await count('studio_audit');
  for (const value of [
    { ...card('c').value, difficulty: 4 }, { ...card('c').value, name: ' Untrimmed ' },
    { ...card('c').value, deleted: true }, { ...card('c').value, role: 'owner_admin' },
    { ...card('c').value, imageReference: 'https://example.test/image.webp' },
    { ...card('c').value, imageReference: `objects/${'a'.repeat(64)}.webp` },
    { ...card('c').value, packId: 'elsewhere' },
  ]) {
    await failure(await commit('pack', 'pack', [op('card', 'a', 'hide'), op('card', 'c', 'create', value)], 1),
      422, 'validation_failed');
  }
  await failure(await commit('pack', 'pack', [op('card', 'a', 'hide'), op('card', 'a', 'hide')], 1), 422, 'validation_failed');
  await failure(await commit('pack', 'pack', [op('pack', 'other', 'hide')], 1), 422, 'validation_failed');
  await failure(await commit('pack', 'pack', [op('card', 'a', 'hide')], undefined), 428, 'precondition_required');
  await failure(await commit('pack', 'pack', [op('card', 'a', 'hide')], 1, { headers: { 'If-None-Match': '*' } }), 400, 'invalid_request');
  await failure(await commit('pack', 'pack', [op('card', 'a', 'hide')], 1, { headers: { 'If-Match': '1' } }), 400, 'invalid_request');
  // Workerd's HTTP ingress omits empty conditional headers, so these reach the
  // handler as missing preconditions. Nonempty malformed headers above stay400.
  await failure(await commit('pack', 'pack', [op('card', 'a', 'hide')], 1, { headers: { 'If-Match': '' } }), 428, 'precondition_required');
  await failure(await commit('pack', 'pack', [op('card', 'a', 'hide')], undefined, { headers: { 'If-None-Match': '' } }), 428, 'precondition_required');
  await failure(await commit('pack', 'pack', [op('card', 'a', 'hide')], 1, { headers: { 'Idempotency-Key': '' } }), 400, 'invalid_request');
  await failure(await send({ protocolVersion: 1, aggregate: { resourceType: 'pack', id: 'pack' },
    operations: [op('card', 'a', 'hide')], actorId: 'owner' }, 1), 422, 'validation_failed');
  for (const body of [
    { protocolVersion: 1, aggregate: { resourceType: ['pack'], id: 'pack' }, operations: [op('card', 'a', 'hide')] },
    { protocolVersion: 1, aggregate: { resourceType: 'pack', id: 'pack' }, operations: [op('card', 'a', ['hide'])] },
    { protocolVersion: 1, aggregate: { resourceType: 'pack', id: 'pack' }, operations: [op(['card'], 'a', 'hide')] },
  ]) await failure(await send(body, 1), 422, 'validation_failed');
  await bucket.put(imageReference, new Uint8Array([1, 2, 3]), { httpMetadata: { contentType: 'image/webp' } });
  await failure(await commit('pack', 'pack', [card('c')], 1), 422, 'validation_failed');
  assert.equal(await row('card', 'c'), null);
  assert.equal((await row('card', 'a')).state, 'active');
  assert.equal((await row('pack', 'pack')).revision, 1);
  assert.equal(await count('studio_audit'), before);
});

test('relationships reject orphan Packs, cross-Pack Cards and Pack reassignment', async t => {
  const { commit, row, seed } = await setup(t); await seed();
  await failure(await commit('pack', 'orphan', [pack('orphan', 'missing')], 0), 422, 'validation_failed');
  await success(await commit('topic', 'other', [topic('other')], 0), 1);
  await failure(await commit('pack', 'pack', [op('pack', 'pack', 'update', { name: 'Moved', topicId: 'other' })], 1), 422, 'validation_failed');
  await success(await commit('pack', 'other-pack', [pack('other-pack'), card('other-card', 'other-pack')], 0), 1);
  await failure(await commit('pack', 'pack', [op('card', 'other-card', 'hide')], 1), 404, 'not_found');
  assert.equal(await row('pack', 'orphan'), null);
  assert.equal((await row('card', 'other-card')).state, 'active');
});

test('Owner soft deletion cascades and records tombstones and audit; hide creates no deletion evidence', async t => {
  const { commit, row, db, count, seed } = await setup(t); await seed();
  await success(await commit('pack', 'pack', [op('pack', 'pack', 'hide')], 1, { actor: 'collector' }), 2);
  assert.equal(await count('studio_tombstones'), 0);
  const before = await count('studio_audit');
  await success(await commit('topic', 'topic', [op('topic', 'topic', 'softDelete')], 1), 2);
  for (const [type, id] of [['topic', 'topic'], ['pack', 'pack'], ['card', 'a'], ['card', 'b']]) {
    assert.equal((await row(type, id)).state, 'deleted');
    const tombstone = await db.prepare('SELECT * FROM studio_tombstones WHERE resource_type = ? AND resource_id = ?').bind(type, id).first();
    assert.ok(tombstone);
    assert.ok(Number.isFinite(Date.parse(tombstone.deleted_at)));
  }
  assert.equal((await row('pack', 'pack')).revision, 3);
  assert.equal(await count('studio_tombstones'), 4);
  assert.equal(await count('studio_audit'), before + 4);
  await failure(await commit('pack', 'pack', [op('pack', 'pack', 'restore')], 3), 422, 'validation_failed');
  await success(await commit('topic', 'topic', [op('topic', 'topic', 'restore')], 2), 3);
  await success(await commit('pack', 'pack', [op('pack', 'pack', 'restore')], 3), 4);
  assert.notEqual((await row('topic', 'topic')).state, 'deleted');
  assert.equal((await row('card', 'a')).state, 'deleted');
  assert.equal(await count('studio_tombstones'), 4);
});

test('permanent deletion requires soft deletion and retains identity fences, audit and tombstones', async t => {
  const { commit, row, count, seed } = await setup(t); await seed();
  await failure(await commit('pack', 'pack', [op('card', 'a', 'permanentDelete')], 1), 422, 'validation_failed');
  await success(await commit('pack', 'pack', [op('pack', 'pack', 'softDelete')], 1), 2);
  await failure(await commit('pack', 'pack', [op('pack', 'pack', 'permanentDelete')], 2), 422, 'validation_failed');
  await success(await commit('pack', 'pack', [op('card', 'a', 'permanentDelete'), op('card', 'b', 'permanentDelete')], 2), 3);
  await success(await commit('pack', 'pack', [op('pack', 'pack', 'permanentDelete')], 3), 4);
  const fence = await row('pack', 'pack');
  assert.equal(fence.state, 'purged');
  assert.equal(fence.value, null);
  assert.equal(await count('studio_tombstones'), 3);
  assert.ok(await count('studio_audit') >= 10);
  await failure(await commit('pack', 'pack', [pack()], 0), 412, 'revision_conflict');
  await failure(await commit('pack', 'pack', [op('pack', 'pack', 'restore')], 4), 410, 'deleted');
});

test('a failed audit insert rolls back content, revision, tombstones and idempotency together', async t => {
  const { commit, db, row, count, seed } = await setup(t); await seed();
  const before = await count('studio_audit');
  await db.exec("CREATE TRIGGER reject_audit BEFORE INSERT ON studio_audit BEGIN SELECT RAISE(ABORT, 'fixture_audit_failure'); END;");
  const key = 'retry-after-storage-recovery';
  await failure(await commit('pack', 'pack', [op('pack', 'pack', 'softDelete')], 1, { key }), 503, 'internal_error');
  assert.equal((await row('pack', 'pack')).state, 'active');
  assert.equal((await row('pack', 'pack')).revision, 1);
  assert.equal((await row('card', 'a')).state, 'active');
  assert.equal(await count('studio_tombstones'), 0);
  assert.equal(await count('studio_audit'), before);
  await db.exec('DROP TRIGGER reject_audit');
  await success(await commit('pack', 'pack', [op('pack', 'pack', 'softDelete')], 1, { key }), 2);
});

test('a full Studio import commits 100 operations with one Pack revision', async t => {
  const { commit, db, count } = await setup(t);
  await success(await commit('topic', 'topic', [topic()], 0), 1);
  const operations = [pack(), ...Array.from({ length: 99 }, (_, i) => card(`card-${i}`))];
  await success(await commit('pack', 'pack', operations, 0, { actor: 'collector' }), 1);
  assert.equal(await db.prepare("SELECT count(*) AS n FROM studio_entities WHERE resource_type = 'card'").first('n'), 99);
  assert.equal(await count('studio_audit'), 101);
  await failure(await commit('pack', 'pack', Array.from({ length: 101 }, (_, i) => card(`overflow-${i}`)), 1,
    { actor: 'collector' }), 422, 'validation_failed');
  assert.equal(await count('studio_audit'), 101);
});

test('single-operation endpoints use the same validated batch and revision boundary', async t => {
  const { commit, row } = await setup(t);
  await success(await commit('topic', 'topic', [topic()], 0, { path: '/studio/v1/topics' }), 1);
  await success(await commit('topic', 'topic', [op('topic', 'topic', 'update', { name: 'Edited' })], 1,
    { path: '/studio/v1/topics/topic', method: 'PATCH' }), 2);
  assert.equal(JSON.parse((await row('topic', 'topic')).value).name, 'Edited');
  await success(await commit('topic', 'topic', [op('topic', 'topic', 'softDelete')], 2,
    { path: '/content/v1/studio/topics/topic', method: 'DELETE' }), 3);
  assert.equal((await row('topic', 'topic')).state, 'deleted');
});

test('global Card identity collisions cannot overwrite another Pack or partially create the batch', async t => {
  const { commit, row, count, seed } = await setup(t); await seed();
  const before = await count('studio_audit');
  await failure(await commit('pack', 'new-pack', [pack('new-pack'), card('a', 'new-pack')], 0),
    422, 'validation_failed');
  assert.equal(await row('pack', 'new-pack'), null);
  assert.equal((await row('card', 'a')).parent_id, 'pack');
  assert.equal((await row('pack', 'pack')).revision, 1);
  assert.equal(await count('studio_audit'), before);
});

test('hide and deletion suppress published catalog/downloads immediately; restore never republishes', async t => {
  const { commit, db, get, seed } = await setup(t); await seed();
  await db.prepare('INSERT INTO catalog_topics VALUES (?, ?, 1, 1, 0)').bind('topic', 'Topic').run();
  await db.prepare('INSERT INTO catalog_packs VALUES (?, ?, ?, 1, 2, ?, 1, 0)')
    .bind('pack', 'topic', 'Pack', 'a'.repeat(64)).run();
  assert.equal((await (await get('/content/v1/catalog/packs?topicId=topic')).json()).items.length, 1);
  await success(await commit('pack', 'pack', [op('card', 'a', 'hide')], 1, { actor: 'collector' }), 2);
  assert.deepEqual((await (await get('/content/v1/catalog/packs?topicId=topic')).json()).items, []);
  await failure(await get('/content/v1/packs/pack/download'), 403, 'unavailable');
  await success(await commit('pack', 'pack', [op('pack', 'pack', 'softDelete')], 2), 3);
  await failure(await get('/content/v1/packs/pack/download'), 410, 'deleted');
  await success(await commit('pack', 'pack', [op('pack', 'pack', 'restore')], 3), 4);
  await failure(await get('/content/v1/packs/pack/download'), 403, 'unavailable');
  assert.deepEqual((await (await get('/content/v1/catalog/packs?topicId=topic')).json()).items, []);
});

test('deleting a restored Topic renews every descendant Pack tombstone monotonically', async t => {
  const { commit, row, count, seed } = await setup(t); await seed();
  await success(await commit('topic', 'topic', [op('topic', 'topic', 'softDelete')], 1), 2);
  await success(await commit('topic', 'topic', [op('topic', 'topic', 'restore')], 2), 3);
  // Descendants remain deleted, but a new authoritative deletion still records
  // newer evidence for clients which synchronized between the two deletions.
  await success(await commit('topic', 'topic', [op('topic', 'topic', 'softDelete')], 3), 4);
  assert.equal((await row('pack', 'pack')).revision, 3);
  assert.equal((await row('card', 'a')).revision, 3);
  assert.equal(await count('studio_tombstones'), 8);
});

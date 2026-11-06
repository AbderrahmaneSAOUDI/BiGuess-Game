import assert from 'node:assert/strict';
import { test } from 'node:test';
import { readFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { Miniflare, convertV4MiniflareOptions } from 'miniflare';
import { root } from '../scripts/local.mjs';

const migration = readFileSync(new URL('../migrations/0002_catalog.sql', import.meta.url), 'utf8')
  .split('\n').filter(line => !line.trim().startsWith('--')).join(' ');
function validate(kind, payload) {
  execFileSync('python3', ['-c', `import json,sys; sys.path.insert(0,'../../scripts'); import validate_content_contract as c; c.validate(sys.argv[1],json.load(sys.stdin))`, kind],
    { cwd: root, input: JSON.stringify(payload), stdio: ['pipe', 'pipe', 'pipe'] });
}
async function setup(t, migrate = true) {
  const mf = new Miniflare(convertV4MiniflareOptions({ modules: true,
    scriptPath: `${root}dist/index.js`, compatibilityDate: '2026-11-01',
    bindings: { APP_ENV: 'staging' }, d1Databases: { DB: 'catalog-test' }, r2Buckets: { CONTENT: 'unused' } }));
  t.after(() => mf.dispose());
  const db = await mf.getD1Database('DB');
  if (migrate) {
    await db.exec(migration);
    const publications = readFileSync(new URL('../migrations/0003_publications.sql', import.meta.url), 'utf8')
      .split('\n').filter(line => !line.trim().startsWith('--')).join(' ');
    await db.exec(publications);
  }
  const get = (path, options) => mf.dispatchFetch(`http://localhost/content/${path}`, options);
  const topic = (id, published = 1, deleted = 0) => db.prepare(
    'INSERT INTO catalog_topics VALUES (?, ?, 1, ?, ?)').bind(id, 'Same label', published, deleted).run();
  const pack = (id, parent = 'A', published = 1, deleted = 0) => db.prepare(
    'INSERT INTO catalog_packs VALUES (?, ?, ?, 7, 4, ?, ?, ?)')
    .bind(id, parent, 'Pack', 'a'.repeat(64), published, deleted).run();
  return { db, get, topic, pack };
}
async function expectError(response, status, code) {
  assert.equal(response.status, status);
  assert.equal(response.headers.get('Cache-Control'), 'no-store');
  assert.equal(response.headers.get('Access-Control-Allow-Origin'), '*');
  const body = await response.json();
  validate('Error', body);
  assert.equal(body.error.code, code);
  return body;
}

test('anonymous catalog is compact, contract-valid and ordered by exact UTF-8 ID bytes', async t => {
  const { get, topic, pack } = await setup(t);
  for (const id of ['😀', 'é', 'a', 'A', '\uE000']) await topic(id);
  await topic('hidden', 0); await topic('deleted', 1, 1);
  await pack('visible'); await pack('draft', 'A', 0); await pack('deleted', 'A', 1, 1);
  await pack('hidden-parent', 'hidden'); await pack('deleted-parent', 'deleted');
  const response = await get('v1/catalog/topics');
  const body = await response.json(); validate('TopicPage', body);
  assert.deepEqual(body.items.map(x => x.id), ['A', 'a', 'é', '\uE000', '😀']);
  const packs = await (await get('v1/catalog/packs?topicId=A')).json(); validate('PackPage', packs);
  assert.deepEqual(packs.items, [{ id: 'visible', name: 'Pack', topicId: 'A', revision: 7,
    cardCount: 4, manifestSha256: 'a'.repeat(64) }]);
  assert.equal(response.headers.get('Access-Control-Allow-Origin'), '*');
  assert.match(response.headers.get('Access-Control-Expose-Headers'), /ETag/);
  assert.equal((await get('v1/catalog/topics', { method: 'OPTIONS', headers: {
    Origin: 'https://mobile.example', 'Access-Control-Request-Headers': 'If-None-Match' } })).status, 204);
  const empty = await (await get('v1/catalog/packs?topicId=a')).json();
  validate('PackPage', empty); assert.deepEqual(empty.items, []); assert.equal(empty.nextCursor, null);
});

test('snapshot pages retain metadata/order despite insertion and edits; cursors bind filters and limit', async t => {
  const { db, get, topic, pack } = await setup(t);
  for (const id of ['A', 'B', 'C']) await topic(id);
  for (const id of ['a', 'b', 'c']) await pack(id);
  const first = await (await get('v1/catalog/topics?limit=1')).json();
  const next = `v1/catalog/topics?limit=1&cursor=${first.nextCursor}`;
  await topic('AA'); await db.exec("UPDATE catalog_topics SET name = 'Renamed', revision = 2 WHERE id = 'B'");
  const second = await (await get(next)).json(); validate('TopicPage', second);
  assert.equal(second.snapshot, first.snapshot); assert.deepEqual(second.items, [{ id: 'B', name: 'Same label', revision: 1 }]);
  const third = await (await get(`v1/catalog/topics?limit=1&cursor=${second.nextCursor}`)).json();
  assert.equal(third.items[0].id, 'C'); assert.equal(third.nextCursor, null);
  for (const path of [next.replace('limit=1', 'limit=2'), next + 'x', next.replace('.1.', '.2.'),
    `v1/catalog/packs?topicId=A&limit=1&cursor=${first.nextCursor}`]) {
    await expectError(await get(path), 400, 'invalid_request');
  }
  const page = await (await get('v1/catalog/packs?topicId=A&limit=1')).json();
  await expectError(await get(`v1/catalog/packs?topicId=B&limit=1&cursor=${page.nextCursor}`), 400, 'invalid_request');
  await db.exec(`UPDATE catalog_snapshots SET expires_at = 0 WHERE id = '${first.snapshot}'`);
  await expectError(await get(next), 409, 'cursor_expired');
});

test('ETags hash exact bytes, revalidate, change with content, and never mask unavailability', async t => {
  const { db, get, topic, pack } = await setup(t);
  await topic('A'); await pack('a'); await pack('b');
  const path = 'v1/catalog/packs?topicId=A&limit=1';
  const response = await get(path); const raw = await response.text();
  const etag = response.headers.get('ETag');
  assert.equal(etag, `"${createHash('sha256').update(raw).digest('hex')}"`);
  assert.equal(response.headers.get('Cache-Control'), 'public, max-age=60, must-revalidate');
  for (const tag of [etag, `"other", W/${etag}`, '*']) {
    const cached = await get(path, { headers: { 'If-None-Match': tag } });
    assert.equal(cached.status, 304); assert.equal(await cached.text(), '');
    assert.equal(cached.headers.get('ETag'), etag);
    assert.equal(cached.headers.get('Cache-Control'), response.headers.get('Cache-Control'));
  }
  assert.equal((await get(path, { headers: { 'If-None-Match': '"miss"' } })).status, 200);
  await db.exec("UPDATE catalog_packs SET name = 'Edited', revision = 8 WHERE id = 'a'");
  assert.notEqual((await get(path)).headers.get('ETag'), etag);
  const next = `${path}&cursor=${JSON.parse(raw).nextCursor}`;
  const nextResponse = await get(next); const nextTag = nextResponse.headers.get('ETag');
  await db.exec("UPDATE catalog_packs SET published = 0 WHERE id = 'a'"); // Even previously consumed entries invalidate.
  await expectError(await get(next, { headers: { 'If-None-Match': nextTag } }), 409, 'cursor_expired');
  await db.exec("UPDATE catalog_topics SET published = 0 WHERE id = 'A'");
  await expectError(await get(path, { headers: { 'If-None-Match': etag } }), 403, 'unavailable');
  await db.exec("UPDATE catalog_topics SET deleted = 1 WHERE id = 'A'");
  await expectError(await get(path), 410, 'deleted');
});

test('Topic visibility changes expire snapshots; errors and unsupported operations use frozen envelopes', async t => {
  const { db, get, topic } = await setup(t);
  await topic('A'); await topic('B');
  const first = await (await get('v1/catalog/topics?limit=1')).json();
  await db.exec("UPDATE catalog_topics SET deleted = 1 WHERE id = 'B'");
  await expectError(await get(`v1/catalog/topics?limit=1&cursor=${first.nextCursor}`), 409, 'cursor_expired');
  await expectError(await get('v1/catalog/packs?topicId=unknown'), 404, 'not_found');
  for (const query of ['limit=0', 'limit=101', 'limit=1.5', 'limit=01', 'limit=', 'limit=1&limit=2', 'cursor=', 'sort=name']) {
    await expectError(await get(`v1/catalog/topics?${query}`), 400, 'invalid_request');
  }
  for (const query of ['', 'topicId=', 'topicId=A%20B', 'topicId=%00']) {
    await expectError(await get(`v1/catalog/packs?${query}`), 400, 'invalid_request');
  }
  await expectError(await get('v2/catalog/topics'), 426, 'unsupported_protocol');
  for (const path of ['v1/cards', 'v1/sessions', 'v1/packs/a/download']) await expectError(await get(path), 404, 'not_found');
  for (const method of ['POST', 'PUT', 'DELETE']) await expectError(await get('v1/catalog/topics', { method }), 400, 'invalid_request');
});

test('missing database schema is a retryable service error, never an empty catalog', async t => {
  const { get } = await setup(t, false);
  const response = await get('v1/catalog/topics');
  assert.equal(response.headers.get('Retry-After'), '5');
  const body = await expectError(response, 503, 'internal_error');
  assert.equal(body.error.retryable, true);
  assert.doesNotMatch(JSON.stringify(body), /SELECT|D1_ERROR|stack/);
});

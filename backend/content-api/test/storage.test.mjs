import assert from 'node:assert/strict';
import { test } from 'node:test';
import { readFileSync, mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { execFileSync } from 'node:child_process';
import { Miniflare, convertV4MiniflareOptions } from 'miniflare';
import { root, wrangler } from '../scripts/local.mjs';

const fixture = JSON.parse(readFileSync(new URL('../fixtures/metadata.json', import.meta.url)));
const image = readFileSync(new URL('../fixtures/image.webp', import.meta.url));
const sql = (path) => readFileSync(new URL(path, import.meta.url), 'utf8')
  .split('\n').filter((line) => !line.trim().startsWith('--')).join(' ');

function runtime(environment = 'local') {
  return new Miniflare(convertV4MiniflareOptions({
    modules: true,
    scriptPath: `${root}dist/index.js`,
    compatibilityDate: '2026-11-01',
    bindings: { APP_ENV: environment },
    d1Databases: { DB: 'test-db' },
    r2Buckets: { CONTENT: 'test-content' },
  }));
}

test('Worker reads D1 metadata and verified R2 bytes; storage failures are bounded', async (t) => {
  const mf = runtime();
  t.after(() => mf.dispose());
  const db = await mf.getD1Database('DB');
  const bucket = await mf.getR2Bucket('CONTENT');
  const request = () => mf.dispatchFetch('http://localhost/__fixture');
  assert.equal((await request()).status, 503); // Missing migration.
  assert.deepEqual(await (await mf.dispatchFetch('http://localhost/health')).json(),
    { status: 'ok', environment: 'local' });
  await db.exec(sql('../migrations/0001_storage_fixtures.sql'));
  assert.equal((await request()).status, 503); // Missing seed.
  await db.exec(sql('../fixtures/seed.sql'));
  await db.exec(sql('../fixtures/seed.sql'));
  assert.equal((await db.prepare('SELECT count(*) AS n FROM storage_fixtures').first()).n, 1);
  assert.deepEqual(await (await request()).json(), { error: 'fixture_object_missing' });
  await bucket.put(fixture.object_key, 'corrupt bytes');
  assert.deepEqual(await (await request()).json(), { error: 'fixture_object_invalid' });
  await bucket.put(fixture.object_key, image, { httpMetadata: { contentType: 'image/webp' } });
  const response = await request();
  assert.equal(response.status, 200);
  assert.equal(response.headers.get('Content-Type'), 'image/webp');
  assert.equal(response.headers.get('X-Content-SHA256'), fixture.sha256);
  assert.deepEqual(Buffer.from(await response.arrayBuffer()), image);
  assert.equal((await mf.dispatchFetch('http://localhost/unknown')).status, 404);
  assert.equal((await mf.dispatchFetch('http://localhost/__fixture', { method: 'POST' })).status, 405);
  await assert.rejects(db.prepare(
    'INSERT INTO storage_fixtures VALUES (?, ?, ?, ?, ?)',
  ).bind('bad', 'bad.webp', 'bad-hash', -1, 'image/webp').run(), /CHECK constraint/);
});

test('staging exposes liveness but never the local fixture', async (t) => {
  const mf = runtime('staging');
  t.after(() => mf.dispose());
  assert.equal((await mf.dispatchFetch('http://localhost/health')).status, 200);
  assert.equal((await mf.dispatchFetch('http://localhost/__fixture')).status, 404);
});

test('Wrangler migrations and seed repeat against isolated persistent local storage', { timeout: 300_000 }, async (t) => {
  const state = mkdtempSync(join(tmpdir(), 'biguess-content-test-'));
  let mf;
  t.after(async () => {
    await mf?.dispose();
    rmSync(state, { recursive: true, force: true });
  });
  const local = ['--env', 'local', '--local', '--persist-to', state];
  wrangler(['d1', 'migrations', 'apply', 'DB', ...local]);
  assert.match(wrangler(['d1', 'migrations', 'apply', 'DB', ...local]), /No migrations to apply/);
  for (let i = 0; i < 2; i++) {
    execFileSync(process.execPath, ['scripts/seed.mjs', '--persist-to', state], {
      cwd: root, timeout: 60_000, stdio: 'pipe',
      env: { ...process.env, WRANGLER_SEND_METRICS: 'false' },
    });
  }
  // Use the same on-disk D1/R2 state layout as Wrangler dev.
  mf = new Miniflare(convertV4MiniflareOptions({
    modules: true, scriptPath: `${root}dist/index.js`, compatibilityDate: '2026-11-01',
    bindings: { APP_ENV: 'local' },
    d1Databases: { DB: '00000000-0000-0000-0000-000000000001' },
    r2Buckets: { CONTENT: 'biguess-content-local' },
    resourcePersistencePath: join(state, 'v3'),
  }));
  const response = await mf.dispatchFetch('http://localhost/__fixture');
  assert.equal(response.status, 200, await response.clone().text());
  assert.deepEqual(Buffer.from(await response.arrayBuffer()), image);
  const db = await mf.getD1Database('DB');
  assert.equal((await db.prepare('SELECT count(*) AS n FROM storage_fixtures').first()).n, 1);
});

test('seed rejects remote/environment overrides before doing any work', () => {
  for (const args of [['--remote'], ['--env', 'staging'], ['--persist-to', '--remote']]) {
    assert.throws(() => execFileSync(process.execPath, ['scripts/seed.mjs', ...args], {
      cwd: root, stdio: 'pipe',
    }), /Usage:/);
  }
});

test('environment bindings stay separate and secrets/local state stay ignored', () => {
  const config = JSON.parse(readFileSync(new URL('../wrangler.json', import.meta.url)));
  assert.equal(config.d1_databases, undefined);
  assert.equal(config.r2_buckets, undefined);
  assert.equal(config.env.production, undefined);
  assert.notEqual(config.env.local.d1_databases[0].database_id, config.env.staging.d1_databases[0].database_id);
  assert.notEqual(config.env.local.r2_buckets[0].bucket_name, config.env.staging.r2_buckets[0].bucket_name);
  for (const name of ['local', 'staging']) {
    assert.equal(config.env[name].vars.APP_ENV, name);
    assert.equal(config.env[name].d1_databases[0].remote, false);
    assert.equal(config.env[name].r2_buckets[0].remote, false);
  }
  for (const path of ['.dev.vars', '.dev.vars.local', '.env', '.env.staging', '.wrangler/state/test', 'node_modules/test']) {
    execFileSync('git', ['check-ignore', path], { cwd: root, stdio: 'pipe' });
  }
});

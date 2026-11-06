import assert from 'node:assert/strict';
import { test } from 'node:test';
import { generateKeyPair, exportJWK, SignJWT } from 'jose';
import { Miniflare, convertV4MiniflareOptions } from 'miniflare';
import { root } from '../scripts/local.mjs';

// Only outbound Google key discovery is mocked. The deployed Worker performs
// real RS256 verification and request authorization, with no auth bypass binding.
const project = 'biguess-auth-test';
const keys = await generateKeyPair('RS256');
const attacker = await generateKeyPair('RS256');
const jwk = { ...await exportJWK(keys.publicKey), kid: 'google-test', alg: 'RS256', use: 'sig' };
const users = [
  { uid: 'owner', email: 'owner@example.test', role: 'owner_admin' },
  { uid: 'collector', email: 'collector@example.test', role: 'collector' },
];
async function token(uid = 'collector', overrides = {}, key = keys.privateKey, header = {}) {
  const now = Math.floor(Date.now() / 1000);
  const claims = { sub: uid, email: `${uid}@example.test`, email_verified: true,
    firebase: { sign_in_provider: 'google.com' }, aud: project,
    iss: `https://securetoken.google.com/${project}`, iat: now - 10,
    auth_time: now - 20, exp: now + 3600, ...overrides };
  for (const field of Object.keys(claims)) if (claims[field] === undefined) delete claims[field];
  return new SignJWT(claims).setProtectedHeader({ alg: 'RS256', kid: jwk.kid, ...header }).sign(key);
}
async function setup(t, bindings = {}, keyResponse = () => Response.json({ keys: [jwk] })) {
  const mf = new Miniflare(convertV4MiniflareOptions({ modules: true,
    scriptPath: `${root}dist/index.js`, compatibilityDate: '2026-11-01',
    bindings: { APP_ENV: 'staging', FIREBASE_PROJECT_ID: project,
      STUDIO_USERS: JSON.stringify(users), ...bindings },
    outboundService: request => {
      assert.equal(request.url, 'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com');
      assert.equal(request.method, 'GET');
      assert.equal(request.headers.get('Authorization'), null);
      return keyResponse();
    },
  }));
  t.after(() => mf.dispose());
  return (path = '/studio/v1/session', jwt, method = 'GET', body, headers = {}) => mf.dispatchFetch(
    `https://api.example${path}`, { method, headers: { ...(jwt ? { Authorization: `Bearer ${jwt}` } : {}), ...headers },
      ...(body === undefined ? {} : { body: JSON.stringify(body) }) });
}
async function expect(response, status, error) {
  assert.equal(response.status, status, await response.clone().text());
  assert.equal(response.headers.get('Cache-Control'), 'no-store');
  const body = await response.json();
  if (error) {
    assert.equal(body.protocolVersion, 1);
    assert.equal(body.error.code, ['auth_unavailable', 'not_implemented'].includes(error) ? 'internal_error' : error);
    assert.equal(typeof body.error.message, 'string');
    assert.match(body.error.requestId, /^[0-9a-f-]{36}$/);
    assert.equal(body.error.retryable, status === 503);
    assert.equal(body.error.currentRevision, null);
    assert.doesNotMatch(JSON.stringify(body), /owner@example|collector@example|eyJ|stack|JOSE/);
  }
  if (status === 401) assert.equal(response.headers.get('WWW-Authenticate'), 'Bearer');
  return body;
}

test('Studio requires a valid Firebase Google identity; anonymous public endpoints remain accessible', async t => {
  const request = await setup(t);
  for (const authorization of ['', 'Basic secret', 'Bearer', 'Bearer a b', 'Bearer not-a-jwt']) {
    await expect(await request(undefined, undefined, 'GET', undefined, { Authorization: authorization }), 401, 'unauthenticated');
  }
  await expect(await request('/studio/v1/packs', undefined, 'POST', {}), 401, 'unauthenticated');
  await expect(await request('/studio/unknown'), 401, 'unauthenticated');
  await expect(await request('/content/v1/studio/batches', undefined, 'POST', {}), 401, 'unauthenticated');
  assert.equal((await request('/health')).status, 200);
  // No database is bound: a public request reaches catalog storage rather than auth.
  const publicResponse = await request('/content/v1/catalog/topics');
  assert.equal(publicResponse.status, 503);
  assert.equal((await publicResponse.json()).error.code, 'internal_error');
});

test('JWT signature, issuer, audience, required claims, provider and time are verified', async t => {
  const request = await setup(t);
  const now = Math.floor(Date.now() / 1000);
  const invalid = [
    { exp: now - 1 }, { iat: now + 60 }, { iat: -1 }, { auth_time: now + 60 }, { auth_time: -1 },
    { iss: 'https://accounts.google.com' }, { aud: 'other-project' }, { aud: [project, 'other'] },
    { sub: '' }, { sub: 'x'.repeat(129) }, { email: 'invalid' }, { email_verified: false },
    { firebase: { sign_in_provider: 'password' } }, { firebase: null },
    ...['sub', 'exp', 'iat', 'auth_time', 'email', 'email_verified', 'firebase'].map(field => ({ [field]: undefined })),
  ];
  for (const claims of invalid) await expect(await request(undefined, await token('collector', claims)), 401, 'unauthenticated');
  await expect(await request(undefined, await token('collector', {}, attacker.privateKey)), 401, 'unauthenticated');
  await expect(await request(undefined, await token('collector', {}, keys.privateKey, { kid: 'unknown' })), 401, 'unauthenticated');
  await expect(await request(undefined, await token('collector', {}, keys.privateKey, { kid: undefined })), 401, 'unauthenticated');
  const unsigned = `${Buffer.from('{"alg":"none"}').toString('base64url')}.${Buffer.from('{}').toString('base64url')}.`;
  await expect(await request(undefined, unsigned), 401, 'unauthenticated');
});

test('only server allowlist grants roles; claims, headers, body and reused email cannot elevate', async t => {
  const request = await setup(t);
  for (const uid of ['outsider', 'moderator', 'community']) {
    await expect(await request(undefined, await token(uid, { role: 'owner_admin', admin: true })), 403, 'forbidden');
  }
  await expect(await request(undefined, await token('outsider', { email: users[0].email })), 403, 'forbidden');
  await expect(await request(undefined, await token('collector', { email: users[0].email })), 403, 'forbidden');
  const forged = await token('collector', { role: 'owner_admin', roles: ['owner_admin'], admin: true });
  assert.deepEqual(await expect(await request(undefined, forged), 200), users[1]);
  const headerInjection = await token('collector', {}, keys.privateKey,
    { jku: 'https://attacker.example/keys', jwk: await exportJWK(attacker.publicKey) });
  assert.deepEqual(await expect(await request(undefined, headerInjection), 200), users[1]);
  assert.deepEqual(await expect(await request(undefined, await token('owner', { email: 'OWNER@EXAMPLE.TEST' })), 200), users[0]);
  await expect(await request('/studio/v1/users/collector', forged, 'PATCH', { role: 'owner_admin' },
    { 'X-Role': 'owner_admin', 'X-User-Id': 'owner' }), 403, 'forbidden');
});

test('Collector may read content and create/edit/hide Packs and Cards; Owner-only operations are forbidden', async t => {
  const request = await setup(t); const jwt = await token();
  for (const resource of ['topics', 'packs', 'cards']) {
    await expect(await request(`/studio/v1/${resource}`, jwt), 501, 'not_implemented');
    for (const [method, suffix] of [['POST', ''], ['PATCH', '/id'], ['POST', '/id/hide']]) {
      await expect(await request(`/studio/v1/${resource}${suffix}`, jwt, method, { name: 'Example' }),
        resource === 'topics' ? 403 : 501, resource === 'topics' ? 'forbidden' : 'not_implemented');
    }
    await expect(await request(`/studio/v1/${resource}/id/publish`, jwt, 'POST'), 403, 'forbidden');
  }
  for (const [method, suffix] of [['GET', ''], ['POST', ''], ['PATCH', '/id']]) {
    await expect(await request(`/studio/v1/users${suffix}`, jwt, method), 403, 'forbidden');
  }
});

test('every deletion and restoration route rejects Collector and permits Owner past the boundary', async t => {
  const request = await setup(t);
  const collector = await token(); const owner = await token('owner');
  await expect(await request('/content/v1/studio/packs/id/restore', collector, 'POST'), 403, 'forbidden');
  await expect(await request('/content/v1/studio/packs/id/restore', owner, 'POST'), 501, 'not_implemented');
  assert.deepEqual(await expect(await request('/content/v1/studio/session', collector), 200), users[1]);
  for (const resource of ['topics', 'packs', 'cards', 'users']) {
    for (const [method, suffix] of [['DELETE', '/id'], ['POST', '/id/soft-delete'],
      ['POST', '/id/permanent-delete'], ['POST', '/id/restore']]) {
      const path = `/studio/v1/${resource}${suffix}`;
      await expect(await request(path, collector, method, { role: 'owner_admin' }), 403, 'forbidden');
      // T24 owns mutations. 501 proves authorization passed, without fake writes.
      await expect(await request(path, owner, method), 501, 'not_implemented');
      await expect(await request(path, undefined, method), 401, 'unauthenticated');
    }
    for (const [method, suffix] of [['POST', ''], ['PATCH', '/id'], ['POST', '/id/hide'], ['POST', '/id/publish']]) {
      await expect(await request(`/studio/v1/${resource}${suffix}`, owner, method), 501, 'not_implemented');
    }
  }
  for (const jwt of [collector, owner]) {
    for (const [method, path] of [['POST', '/studio/v1/batch'], ['PUT', '/studio/v1/cards/id'],
      ['POST', '/studio/v1/cards/id/unknown'], ['DELETE', '/studio/v1/cards'], ['GET', '/studio/v1/cards/id/restore']]) {
      await expect(await request(path, jwt, method), 404, 'not_found');
    }
  }
});

test('missing/malformed/unsupported server role configuration fails closed without leaking it', async t => {
  const jwt = await token();
  for (const bindings of [{ FIREBASE_PROJECT_ID: '' }, { STUDIO_USERS: '' }, { STUDIO_USERS: '{' },
    { STUDIO_USERS: '{}' }, { STUDIO_USERS: '[null]' },
    { STUDIO_USERS: JSON.stringify([{ ...users[1], role: 'moderator' }]) }]) {
    const request = await setup(t, bindings);
    await expect(await request(undefined, jwt), 503, 'auth_unavailable');
  }
  const request = await setup(t, { STUDIO_USERS: JSON.stringify([users[1], users[1]]) });
  await expect(await request(undefined, jwt), 403, 'forbidden');
});

test('Google key discovery outages and invalid key sets fail closed as service errors', async t => {
  for (const response of [() => new Response('unavailable', { status: 503 }),
    () => new Response('invalid json'), () => Response.json({ keys: null })]) {
    const request = await setup(t, {}, response);
    await expect(await request(undefined, await token()), 503, 'auth_unavailable');
  }
});

import { createRemoteJWKSet, errors, jwtVerify } from 'jose';
import type { Env } from './env';

// Fixed endpoint; callers cannot choose the key server through JWT headers.
const googleKeys = createRemoteJWKSet(new URL(
  'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com',
), { timeoutDuration: 5000 });

export class StudioError extends Error {
  constructor(readonly status: number, readonly code: string) { super(code); }
}
export type Role = 'owner_admin' | 'collector';
export interface Principal { uid: string; email: string; role: Role }

export async function authenticate(request: Request, env: Env): Promise<Principal> {
  const authorization = request.headers.get('Authorization');
  if (!authorization || !/^Bearer [^\s]+$/i.test(authorization)) {
    throw new StudioError(401, 'unauthenticated');
  }
  if (!env.FIREBASE_PROJECT_ID || !env.STUDIO_USERS) {
    throw new StudioError(503, 'auth_unavailable');
  }
  let payload;
  try {
    ({ payload } = await jwtVerify(authorization.slice(7), (header, token) => {
      if (typeof header.kid !== 'string' || !header.kid) {
        throw new errors.JWTInvalid('Missing signing key ID');
      }
      return googleKeys(header, token);
    }, {
      algorithms: ['RS256'], issuer: `https://securetoken.google.com/${env.FIREBASE_PROJECT_ID}`,
      audience: env.FIREBASE_PROJECT_ID,
      requiredClaims: ['sub', 'iat', 'exp', 'auth_time', 'email', 'email_verified', 'firebase'],
    }));
  } catch (error) {
    if (error instanceof errors.JWTClaimValidationFailed || error instanceof errors.JWTExpired
      || error instanceof errors.JWTInvalid || error instanceof errors.JWSInvalid
      || error instanceof errors.JWSSignatureVerificationFailed
      || error instanceof errors.JOSEAlgNotAllowed || error instanceof errors.JOSENotSupported
      || error instanceof errors.JWKSNoMatchingKey) throw new StudioError(401, 'unauthenticated');
    throw new StudioError(503, 'auth_unavailable');
  }
  const now = Math.floor(Date.now() / 1000);
  const firebase = payload.firebase as { sign_in_provider?: unknown } | undefined;
  if (!payload.sub || payload.sub.length > 128 || payload.aud !== env.FIREBASE_PROJECT_ID
    || typeof payload.iat !== 'number' || !Number.isFinite(payload.iat) || payload.iat > now || payload.iat < 0
    || typeof payload.auth_time !== 'number' || !Number.isFinite(payload.auth_time)
    || payload.auth_time > now || payload.auth_time < 0
    || typeof payload.email !== 'string' || !payload.email.includes('@')
    || payload.email_verified !== true || firebase?.sign_in_provider !== 'google.com') {
    throw new StudioError(401, 'unauthenticated');
  }
  // Only server-managed data grants roles; custom claims/headers/body are ignored.
  // UID binding also prevents a different Firebase account reusing an email.
  let users: unknown;
  try { users = JSON.parse(env.STUDIO_USERS); } catch {
    throw new StudioError(503, 'auth_unavailable');
  }
  if (!Array.isArray(users) || !users.every(user => user
    && typeof user.uid === 'string' && typeof user.email === 'string'
    && (user.role === 'owner_admin' || user.role === 'collector'))) {
    throw new StudioError(503, 'auth_unavailable');
  }
  const email = payload.email.toLowerCase();
  const matches = users.filter(user => user.uid === payload.sub && user.email.toLowerCase() === email);
  if (matches.length !== 1) throw new StudioError(403, 'forbidden');
  return { uid: payload.sub, email, role: matches[0].role };
}

export type Resource = 'session' | 'topics' | 'packs' | 'cards' | 'users';
export type Action = 'read' | 'create' | 'edit' | 'hide' | 'publish'
  | 'soft-delete' | 'permanent-delete' | 'restore';
export function authorize(principal: Principal, resource: Resource, action: Action): void {
  if (principal.role === 'owner_admin') return;
  if (principal.role === 'collector' && ((action === 'read' && resource !== 'users')
    || ((resource === 'packs' || resource === 'cards')
      && (action === 'create' || action === 'edit' || action === 'hide')))) return;
  throw new StudioError(403, 'forbidden');
}

// Explicit item route/action mapping. The batch handler validates schemas and
// authorizes every operation before writing. Unknown routes fail closed.
export function studioOperation(method: string, path: string):
  { resource: Resource; action: Action } | undefined {
  if (method === 'GET' && path === '/studio/v1/session') return { resource: 'session', action: 'read' };
  const match = /^\/studio\/v1\/(topics|packs|cards|users)(?:\/[^/]+(?:\/(hide|publish|soft-delete|permanent-delete|restore))?)?$/.exec(path);
  if (!match) return;
  const resource = match[1] as Resource;
  const hasId = path.split('/').length >= 5;
  const action = match[2] as Action | undefined;
  if (method === 'POST' && action) return { resource, action };
  if (action) return;
  if (method === 'GET') return { resource, action: 'read' };
  if (method === 'POST' && !hasId) return { resource, action: 'create' };
  if (method === 'PATCH' && hasId) return { resource, action: 'edit' };
  if (method === 'DELETE' && hasId) return { resource, action: 'soft-delete' };
}

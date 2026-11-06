import type { Env } from './env';
import { authenticate, authorize, studioOperation, StudioError } from './studio-auth';
import { catalog } from './catalog';
import { download } from './download';

interface Fixture {
  object_key: string;
  sha256: string;
  byte_length: number;
  content_type: string;
}

const json = (value: unknown, status = 200) => Response.json(value, {
  status,
  headers: { 'Cache-Control': 'no-store' },
});

// Studio shares the frozen content error envelope, without exposing JWTs,
// allowlist entries, or upstream key-discovery failures.
function studioError(status: number, code: string): Response {
  return json({ protocolVersion: 1, error: {
    code: code === 'auth_unavailable' || code === 'not_implemented' ? 'internal_error' : code,
    message: code === 'not_implemented' ? 'Studio operation is not implemented.'
      : code === 'auth_unavailable' ? 'Studio authentication is unavailable.'
      : code === 'unauthenticated' ? 'A valid Firebase Google ID token is required.'
      : code === 'forbidden' ? 'Studio access is forbidden.' : 'Endpoint not found.',
    requestId: crypto.randomUUID(), retryable: status === 503, currentRevision: null,
  } }, status);
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const path = new URL(request.url).pathname;
    // Protect the frozen /content/v1/studio namespace before public routing.
    const studioPath = path === '/content/v1/studio' || path.startsWith('/content/v1/studio/')
      ? path.replace('/content/v1/studio', '/studio/v1') : path;
    if (studioPath === '/studio' || studioPath.startsWith('/studio/')) {
      try {
        const principal = await authenticate(request, env);
        const operation = studioOperation(request.method, studioPath);
        if (!operation) return studioError(404, 'not_found');
        authorize(principal, operation.resource, operation.action);
        if (operation.resource === 'session') return json(principal);
        // T23 installs the boundary; content reads/writes belong to T24.
        return studioError(501, 'not_implemented');
      } catch (error) {
        if (error instanceof StudioError) {
          const response = studioError(error.status, error.code);
          if (error.status === 401) response.headers.set('WWW-Authenticate', 'Bearer');
          return response;
        }
        return studioError(503, 'auth_unavailable');
      }
    }
    if (path.startsWith('/content/v1/packs/')) return download(request, env);
    if (path === '/content' || path.startsWith('/content/')) return catalog(request, env);
    if (request.method !== 'GET') return json({ error: 'method_not_allowed' }, 405);
    // Process liveness deliberately does not depend on storage availability.
    if (path === '/health') return json({ status: 'ok', environment: env.APP_ENV });

    // Infrastructure smoke fixture, not a public catalog/download contract.
    if (path !== '/__fixture' || env.APP_ENV !== 'local') {
      return json({ error: 'not_found' }, 404);
    }
    try {
      const fixture = await env.DB.prepare(
        'SELECT object_key, sha256, byte_length, content_type FROM storage_fixtures WHERE id = ?',
      ).bind('fixture-image-v1').first<Fixture>();
      if (!fixture) return json({ error: 'fixture_not_seeded' }, 503);
      const object = await env.CONTENT.get(fixture.object_key);
      if (!object) return json({ error: 'fixture_object_missing' }, 503);
      const bytes = await object.arrayBuffer();
      const hash = Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', bytes)))
        .map((byte) => byte.toString(16).padStart(2, '0')).join('');
      if (bytes.byteLength !== fixture.byte_length || hash !== fixture.sha256) {
        return json({ error: 'fixture_object_invalid' }, 503);
      }
      return new Response(bytes, { headers: {
        'Content-Type': fixture.content_type,
        'Cache-Control': 'no-store',
        'X-Content-SHA256': hash,
      } });
    } catch {
      return json({ error: 'storage_unavailable' }, 503);
    }
  },
} satisfies ExportedHandler<Env>;

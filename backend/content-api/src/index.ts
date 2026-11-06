import type { Env } from './env';
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

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const path = new URL(request.url).pathname;
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

// Test-only trusted operator entrypoint; excluded from the deployed Worker bundle.
import worker from '../src/index';
import { publish, type Bundle } from '../src/publication';
import type { Env } from '../src/env';
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (new URL(request.url).pathname !== '/__publish') return worker.fetch(request, env);
    const { bundle, expectedRevision, failAfter, observeRevision } = await request.json() as { bundle: Bundle; expectedRevision: number; failAfter?: number; observeRevision?: number };
    let writes = 0;
    const content = new Proxy(env.CONTENT, { get(target, property) {
      if (property === 'put') return async (...args: Parameters<R2Bucket['put']>) => {
        const visible = await env.DB.prepare('SELECT revision FROM catalog_packs WHERE id = ?')
          .bind(bundle.receipt.statement.packId).first<{ revision: number }>();
        if (observeRevision !== undefined && (visible?.revision ?? 0) !== observeRevision) throw new Error('partial_visibility');
        if (++writes === failAfter) throw new Error('injected_failure');
        return target.put(...args);
      };
      const value = Reflect.get(target, property);
      return typeof value === 'function' ? value.bind(target) : value;
    } });
    try {
      await publish({ ...env, CONTENT: content }, bundle, expectedRevision);
      return Response.json({ ok: true });
    } catch (error) {
      return Response.json({ error: String(error) }, { status: 409 });
    }
  },
};

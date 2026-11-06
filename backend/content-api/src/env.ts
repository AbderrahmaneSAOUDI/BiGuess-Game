/** Bindings must be repeated for each Wrangler environment (not inherited). */
export interface Env {
  DB: D1Database;
  CONTENT: R2Bucket;
  APP_ENV: 'local' | 'staging';
}

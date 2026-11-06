import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { resolve } from 'node:path';
import { root, wrangler } from './local.mjs';

// Only a state-directory override is supported. Never forward arbitrary Wrangler flags.
const args = process.argv.slice(2);
if (args.length && (args.length !== 2 || args[0] !== '--persist-to' || args[1].startsWith('-'))) {
  throw new Error('Usage: npm run seed -- [--persist-to <local-directory>]');
}
const state = args.length ? ['--persist-to', resolve(args[1])] : [];
const metadata = JSON.parse(readFileSync(new URL('../fixtures/metadata.json', import.meta.url)));
const image = readFileSync(new URL('../fixtures/image.webp', import.meta.url));
if (createHash('sha256').update(image).digest('hex') !== metadata.sha256 || image.length !== metadata.byte_length) {
  throw new Error('Fixture bytes differ from metadata');
}
// Put bytes first: a failed upload cannot leave metadata referencing a missing object.
console.log(wrangler(['r2', 'object', 'put', `biguess-content-local/${metadata.object_key}`,
  '--file', 'fixtures/image.webp', '--content-type', metadata.content_type,
  '--env', 'local', '--local', ...state]));
console.log(wrangler(['d1', 'execute', 'DB', '--file', `${root}fixtures/seed.sql`,
  '--env', 'local', '--local', ...state]));

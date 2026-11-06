/** Offline only: validate T09 bytes, then sign with an operator-owned Ed25519 key. */
import { execFileSync } from 'node:child_process';
import { createPrivateKey, createPublicKey, sign, createHash } from 'node:crypto';
import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const hash = (bytes) => createHash('sha256').update(bytes).digest('hex');
export function prepare(archivePath, privateKeyPem) {
  const artifacts = JSON.parse(execFileSync('python3', [
    fileURLToPath(new URL('./prepare.py', import.meta.url)), archivePath,
  ], { maxBuffer: 256 * 1024 * 1024 }));
  const manifestBytes = Buffer.from(artifacts.manifest, 'base64');
  const manifest = JSON.parse(manifestBytes);
  const archive = Buffer.from(artifacts.archive, 'base64');
  const key = createPrivateKey(privateKeyPem);
  if (key.asymmetricKeyType !== 'ed25519') throw new Error('Ed25519 key required');
  const publicKey = createPublicKey(key).export({ type: 'spki', format: 'der' });
  // Alphabetical field order is part of the detached receipt v1 encoding.
  const statement = {
    archiveSha256: hash(archive), archiveSizeBytes: archive.length,
    domain: 'biguess-pack-publication-v1', manifestSha256: hash(manifestBytes),
    manifestSizeBytes: manifestBytes.length, packId: manifest.pack.id,
    revision: manifest.pack.revision, topicId: manifest.topic.id,
  };
  const keyId = hash(publicKey);
  const receipt = { schemaVersion: 1, algorithm: 'Ed25519', keyId, statement,
    signature: sign(null, Buffer.from(JSON.stringify(statement) + '\n'), key).toString('base64') };
  return { ...artifacts, receipt, trustedKeys: { [keyId]: publicKey.toString('base64') } };
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  if (process.argv.length !== 5) throw new Error('Usage: node scripts/prepare.mjs ARCHIVE PRIVATE_KEY_PEM OUTPUT_JSON');
  const bundle = prepare(process.argv[2], readFileSync(process.argv[3]));
  writeFileSync(process.argv[4], JSON.stringify(bundle) + '\n', { flag: 'wx', mode: 0o600 });
}

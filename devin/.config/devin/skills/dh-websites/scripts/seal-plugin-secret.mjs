#!/usr/bin/env node
// seal-plugin-secret.mjs — seal an EmDash plugin secret setting into the
// AES-256-GCM envelope emdash expects in the `options` table.
//
// Mirrors node_modules/emdash/src/plugins/settings.ts byte-for-byte:
//   {$emdash:"plugin-setting", v:1, kid, iv, ciphertext}
//   AAD = JSON.stringify(["emdash-plugin-setting", 1, pluginId, settingKey])
//   kid = first 8 lowercase-hex chars of sha256(raw key bytes)
// Uses WebCrypto subtle.encrypt — ciphertext+tag come back concatenated.
// (Hand-rolled crypto.createCipheriv drops the GCM tag unless you append it;
// that bug silently killed every email send on one site — hence this script.)
//
// SELF-CHECK: decrypts its own envelope with emdash's exact routine before
// printing anything. If the check fails the script exits non-zero and prints
// nothing — a malformed envelope never reaches the database.
//
// Usage:
//   node seal-plugin-secret.mjs --plugin dh-resend --setting apiKey --sql
//     (plaintext read from stdin — keeps it out of shell history)
//   node seal-plugin-secret.mjs --plugin dh-resend --setting apiKey --value re_xxx
//   echo '{"x":1}' | node seal-plugin-secret.mjs --plugin p --setting s --sql
//   node seal-plugin-secret.mjs --kid-only            # print kid of the key
//
// Key source: --key <emdash_enc_v1_...> or $EMDASH_ENCRYPTION_KEY. A
// comma-separated list is fine — the FIRST entry is used (it's the primary,
// same as emdash's resolved[0]).
import { createHash } from 'node:crypto';
import { subtle } from 'node:crypto';

const PREFIX = 'emdash_enc_v1_';
const IV_BYTES = 12;

function b64urlDecode(s) {
  return new Uint8Array(Buffer.from(s.replace(/-/g, '+').replace(/_/g, '/'), 'base64'));
}
const b64urlEncode = (bytes) =>
  Buffer.from(bytes).toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');

const aad = (pluginId, key) =>
  new TextEncoder().encode(JSON.stringify(['emdash-plugin-setting', 1, pluginId, key]));

function parseKey(raw) {
  const entry = raw.split(',').map((s) => s.trim()).filter(Boolean)[0];
  if (!entry?.startsWith(PREFIX))
    die(`key must start with ${PREFIX} (generate: npx emdash secrets generate)`);
  const bytes = b64urlDecode(entry.slice(PREFIX.length));
  if (bytes.length !== 32) die(`key body must decode to 32 bytes, got ${bytes.length}`);
  return { bytes, kid: createHash('sha256').update(bytes).digest('hex').slice(0, 8) };
}

function die(msg, code = 1) {
  console.error(`seal: ${msg}`);
  process.exit(code);
}

async function seal(pluginId, settingKey, plaintext, key) {
  const iv = crypto.getRandomValues(new Uint8Array(IV_BYTES));
  const ck = await subtle.importKey('raw', key.bytes, 'AES-GCM', false, ['encrypt', 'decrypt']);
  const ct = await subtle.encrypt(
    { name: 'AES-GCM', iv, additionalData: aad(pluginId, settingKey) },
    ck,
    new TextEncoder().encode(plaintext),
  );
  return {
    $emdash: 'plugin-setting',
    v: 1,
    kid: key.kid,
    iv: b64urlEncode(iv),
    ciphertext: b64urlEncode(new Uint8Array(ct)),
  };
}

// emdash's decrypt routine, reimplemented — the script refuses to emit an
// envelope this can't round-trip.
async function verify(pluginId, settingKey, envelope, key, expected) {
  if (envelope.kid !== key.kid) die(`self-check: kid mismatch`);
  const ck = await subtle.importKey('raw', key.bytes, 'AES-GCM', false, ['decrypt']);
  try {
    const pt = await subtle.decrypt(
      { name: 'AES-GCM', iv: b64urlDecode(envelope.iv), additionalData: aad(pluginId, settingKey) },
      ck,
      b64urlDecode(envelope.ciphertext),
    );
    if (new TextDecoder().decode(pt) !== expected) die('self-check: plaintext mismatch');
  } catch {
    die('self-check: envelope failed to decrypt — do NOT write it');
  }
}

// ── args ────────────────────────────────────────────────────────────────────
const args = process.argv.slice(2);
const opt = (name) => {
  const i = args.indexOf(name);
  return i === -1 ? undefined : args[i + 1];
};
const flag = (name) => args.includes(name);

const plugin = opt('--plugin');
const setting = opt('--setting');
if (flag('--kid-only')) {
  const key = parseKey(opt('--key') ?? process.env.EMDASH_ENCRYPTION_KEY ?? die('no key given'));
  console.log(key.kid);
  process.exit(0);
}
if (!plugin || !setting) die('--plugin and --setting are required (or --kid-only)');

const key = parseKey(opt('--key') ?? process.env.EMDASH_ENCRYPTION_KEY ?? die('no key — pass --key or set EMDASH_ENCRYPTION_KEY'));

let plaintext = opt('--value');
if (plaintext === undefined) {
  plaintext = await new Promise((resolve) => {
    let buf = '';
    process.stdin.on('data', (d) => (buf += d)).on('end', () => resolve(buf));
  });
  plaintext = plaintext.trim();
}
if (!plaintext) die('empty plaintext — pass --value or pipe stdin');

const envelope = await seal(plugin, setting, plaintext, key);
await verify(plugin, setting, envelope, key, plaintext);

const json = JSON.stringify(envelope);
if (flag('--sql')) {
  const name = `plugin:${plugin}:settings:${setting}`;
  const esc = json.replace(/'/g, "''");
  console.log(
    `INSERT INTO options (name, value, revision) VALUES ('${name}', '${esc}', '1')\n` +
      `ON CONFLICT(name) DO UPDATE SET value = excluded.value, revision = CAST(CAST(options.revision AS INTEGER) + 1 AS TEXT);`,
  );
} else {
  console.log(json);
}

# EmDash ops — the shared playbook

Canonical reference for operating EmDash sites on Cloudflare Workers (the DH
fleet). Site-specific facts stay in each repo's `AGENTS.md`; anything here
applies fleet-wide. Reach for this when doing **DB writes, plugin settings,
schema changes, admin-user work, or wrangler CLI ops** — not for design/copy.

Reference source: `node_modules/emdash/src/` in any EmDash repo (the runtime
is bundled — read it when behavior is in doubt, don't guess).

## Wrangler CLI — the loud parts

- **Remote mutations always need `--remote`.** `d1 execute`, `kv key`,
  `r2 object` all default to LOCAL miniflare state. `[]` from a local
  `kv key list` ≠ an empty namespace — it's just the local one.
- **Slim `d1` output** — the CLI wraps results in ~40 lines of banner + meta.
  Pipe `--json` through an extractor:

  ```bash
  direnv exec . npx wrangler d1 execute <db> --remote --json \
    --command "SELECT ..." \
    | python3 -c "import sys,json;d=json.load(sys.stdin);[print(r) for r in d[0]['results']]"
  ```

- **`kv key list` is eventually consistent** — a key written seconds ago can
  be absent from list output. `kv key get` reads fresher. Don't treat a
  missing list entry as proof a write failed.
- **Deploy reads `dist/server/wrangler.json`, not `wrangler.jsonc`.** After
  editing `wrangler.jsonc` (bindings, vars) run `npm run build` FIRST or the
  deploy ships the stale generated config. `just deploy`/`npm run deploy`
  chains them — never bare `wrangler deploy`.
- **Deploy propagation lag** — `wrangler deploy` returns before the new
  version serves everywhere. Wait ~10–15s (or retry) before hitting changed
  API routes; for pages, grep served HTML for a marker only the new build
  emits before running Lighthouse/screenshots.
- **`wrangler secret put` bakes the `KEY=` prefix in.** When piping a
  `KEY=value` env line into `wrangler secret put <KEY>`, the whole line
  becomes the secret value — `EMDASH_ENCRYPTION_KEY` ended up containing
  `EMDASH_ENCRYPTION_KEY=<value>` and had to be re-put. Pipe only the raw
  value: `grep -o 'emdash_enc_v1_[A-Za-z0-9_-]*' .dev.vars | head -1 | tr -d '\n' | npx wrangler secret put EMDASH_ENCRYPTION_KEY`
  (secretive-saver).
- **Non-interactive prompts take the fallback.** In a headless exec,
  wrangler answers its own questions with `🤖 Using fallback value in
  non-interactive context: no` — e.g. `d1 create` offered to edit
  `wrangler.jsonc` for you and declined. Don't rely on the offer; copy the
  new `database_id`/KV `id` into `wrangler.jsonc` yourself (D1/R2 still
  auto-provision on first deploy; KV `SESSION` must be pinned per below).

## Options table & plugin settings

- `options` columns: `(name TEXT PK, value TEXT NOT NULL, revision TEXT)`.
  Plugin settings live at `plugin:<pluginId>:settings:<key>`; `value` is a
  JSON string. Bump `revision` on manual writes.
- **Secret settings** (`apiKey` etc.) are AES-256-GCM **envelopes**, not
  plaintext. Generate them with the checked-in script (it self-verifies the
  envelope before printing — never hand-roll crypto for this):

  ```bash
  # key comes from the site's .dev.vars EMDASH_ENCRYPTION_KEY
  export EMDASH_ENCRYPTION_KEY=$(grep -o 'emdash_enc_v1_[A-Za-z0-9_-]*' .dev.vars | head -1)
  echo -n "re_REAL_KEY" | node <skill>/scripts/seal-plugin-secret.mjs \
    --plugin <plugin-id> --setting apiKey --sql | \
    xargs -0 -I{} direnv exec . npx wrangler d1 execute <db> --remote --command "{}"
  ```

  Envelope format (for reference): `{$emdash:"plugin-setting", v:1, kid, iv,
  ciphertext}`; `kid` = first 8 hex of sha256(raw key bytes); AAD =
  `["emdash-plugin-setting",1,pluginId,settingKey]`; WebCrypto
  `subtle.encrypt` output (ciphertext+tag concatenated) — Node's
  `createCipheriv` does NOT append the tag automatically and produces
  undecryptable envelopes.
- **A setting is only secret if the plugin declares it.** The plugin file
  itself must list the field as `type: "secret"` in its
  `admin.settingsSchema` — declaring it only in `astro.config.mjs` gives
  `Encrypted plugin setting is not declared as a secret` at runtime.
- **Selecting a transport needs the hook row.** For exclusive hooks
  (e.g. `email:deliver`), a registered plugin isn't active until an
  `options` row selects it:
  `emdash:exclusive_hook:email:deliver = "<plugin-id>"`.
- **`.dev.vars` key must match the deployed `EMDASH_ENCRYPTION_KEY` secret.**
  Envelopes sealed with the wrong key fail decrypt at runtime
  (`PluginSettingEncryptionError`) — and email sends die silently. Check
  alignment by kid: `node seal-plugin-secret.mjs --kid-only` vs
  `json_extract(value,'$.kid')` on an existing envelope row. If `.dev.vars`
  drifted, either re-seal the rows with the deployed key or realign the
  secret (`wrangler secret put`) and re-seal.

## Schema changes after first deploy

The seed only applies on a fresh DB. Post-deploy changes go through the
schema REST API with a throwaway PAT:

1. `INSERT INTO _emdash_api_tokens` — raw token `ec_pat_<b64url 32B>`,
   `token_hash` = base64url(sha256(raw)), `scopes='["admin"]'`, `user_id`
   must reference a real `users` row (FK — on a zero-user site, insert a
   throwaway user first; deleting the user cascades the token).
2. `npx emdash schema create` / `add-field --url <site> -t <token>`.
   `default_value`/`validation` args are JSON-encoded; the CLI can't set
   select options — `UPDATE _emdash_fields` directly after.
3. Revoke the PAT.

Collection rows live in `ec_<collection>` — **wide tables with per-field
columns** (id, title, slug, status, then one column per field). There is no
`data` JSON column; check `PRAGMA table_info(ec_<name>)` before querying.

## Users & the admin wizard

- **`createFirstAdmin` hard-refuses when `users` is non-empty** — a
  hand-inserted user row locks out the setup wizard (magic-link lookup
  finds the row but it has no credentials → dead end both ways). If you
  need an admin on a fresh site, run the wizard; never insert users
  manually.
- Magic link: `POST /_emdash/api/auth/magic-link/send {"email"}` —
  15-min tokens in `auth_tokens`. Requires the `email:deliver` hook
  configured (above) or the send 500s.
- **Passkeys are origin-bound** — a passkey registered on a preview
  subdomain won't work on the production domain. Re-register per origin.
- **Mail scanners consume GET links.** Outlook SafeLinks prefetches emailed
  URLs ~seconds after delivery — a GET-consumes-token design serves users
  dead links. One-time tokens must be consumed on POST (GET can render an
  auto-submit interstitial).
- **"Client can't login" triage order** (reveal-fitness invite session):
  1. Does a `users` row exist for the email? (`users` columns are
     `id,email,name,role,disabled,created_at,updated_at` — there is no
     `status` column; a `WHERE status=...` query fails `no such column`).
  2. Any pending row in `auth_tokens` where `type='invite'` for the email?
     Invite links are `{site}/_emdash/admin/invite/accept?token=<raw>`;
     rows expire (~7 days) and are gone once consumed/expired.
  3. Is `email:deliver` actually wired — the
     `emdash:exclusive_hook:email:deliver` option row plus a sealed
     `plugin:<id>:settings:apiKey`? No user + no invite + no hook =
     nothing was ever sent.
  Re-inviting an email that already has a `users` row is rejected
  `user_exists` — that path needs account recovery, not another invite.
- **`emdash login -u <site-url>`** is the supported CLI auth for a remote
  instance — OAuth device flow (RFC 8628): prints a URL+code, an admin
  approves in a browser, tokens persist to `~/.config/emdash/auth.json`.
  `--header "Name: Value"` / `EMDASH_HEADERS` carries auth for sites
  behind Cloudflare Access or similar proxies. Then `emdash
  content|schema|media|site …` work headlessly.
- **`emdash site export` / `site import`** is the move-accounts path
  (replaced cloning D1 statement-by-statement, which choked on EmDash's
  FTS5 tables): `npx emdash site export --url https://old --output
  site.emdash`, then `npx emdash site import site.emdash --url https://new
  --analyze --plan sha256:<hex> --confirm`. Users/passkeys do NOT migrate
  (admins re-register; passkeys are origin-bound anyway). When the site
  has no real content/users, skip the export entirely — a fresh deploy +
  setup wizard is cheaper (hofackers: user chose fresh deploy over the
  ~10-step export migration).

## Email / Resend

- The fleet's shared Resend key is **send-only** — it cannot read the send
  log (`401` on `emails.get`). Delivery questions need the Resend
  dashboard; don't try to verify sends through the API.
- `mydigitalharbor.com` is Proton-controlled for inbound mail — never touch
  MX when changing DNS. A future `@mydigitalharbor.com` sender migration
  merges `include:resend.com` into the existing SPF (merge, don't replace).
- Proton aggressively junks `noreply@<unfamiliar-domain>` — check spam
  before concluding a send failed.

## Build & install

- **`npm install` needs `--legacy-peer-deps`** — @astrojs/cloudflare 14.x
  declares `peer astro ^7.4` but runs fine on the pinned 7.3.x.
- **KV `SESSION` must be pinned** in `wrangler.jsonc` (`id`) or wrangler
  errors on deploy — EmDash injects a bare SESSION binding.
- First request after a cold deploy runs migrations (~60s) — expect a slow
  first load.
- Local dev admin without the wizard: hit `/` once (migrations), then
  `/_emdash/api/setup/dev-bypass?redirect=/_emdash/admin`.
- `npx emdash types` regenerates `emdash-env.d.ts` but needs an
  authenticated session — skip it; builds don't require it.
- **Astro 7 + `@astrojs/cloudflare` 14 is required.** Astro 6 + adapter 13
  fails the build with `require_dist is not a function` inside workerd —
  the older esbuild pipeline can't bundle emdash 1.x's CJS chunks. All
  EmDash siblings run astro 7 (jacobs AGENTS.md gotcha).
- **`site:`/`siteUrl` bake the host into generated files.** After an
  account or domain move, if `astro.config.mjs` `site:` and the emdash
  `siteUrl` still point at the old URL, `feed.xml` emits `localhost:4321`
  and `sitemap-*.xml` emits the stale host. Post-move verification must
  include: `curl -s <new-url>/feed.xml | grep -o '<old-host>'` and same
  for sitemap URLs (jacobs cleanup 2026-10-28).

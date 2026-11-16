# Projects

Inventory of `~/projects/personal/`. Read when a task names a repo you can't see, or asks which project owns something.

## Client and business websites

Most deploy to Cloudflare via `wrangler`; several carry ansible playbooks for server provisioning.

**Deploy map:** the live URL is always `https://<wrangler.jsonc "name">.<account-subdomain>.workers.dev`. Which account/subdomain each site uses lives in `terraform-cloudflare-factory/registry/sites.yaml` (and `accounts/<client>/`). Dedicated-account clients have their own accounts; demos, hosted sites, and shared-account clients share the Digital Harbor account (`digitalharbor.workers.dev`); personal sites share `nicpayne713`. Zoneless DH-account sites also serve at `<slug>.mydigitalharbor.com` — custom domains tofu-managed in `DigitalHarbor/infra/dns.tf` (fleet `for_each` map). **Always source the site's `.envrc` (per-account `CLOUDFLARE_ACCOUNT_ID` + deploy token) before any `wrangler`/D1/R2 op** — default wrangler auth is the personal OAuth account, so `wrangler d1 execute` on a client DB reports "database not found". Tokens regenerate via `tofu -chdir=accounts/<acct> output -raw deploy_token` inside terraform-cloudflare-factory.

| repo | what it is |
| --- | --- |
| 1man1band-website | band site (EmDash on CF Workers, Digital Harbor account — `1man1band.com` + `1man1.band`) |
| church-calendar-homepage | church calendar site (node + compose, not wrangler) |
| claritycare-website | prospect demo — Clarity Care (Fox Cities nonprofit care agency, claritycare.org); static Astro + Worker `/api/contact` → Resend, DH account (`claritycare.mydigitalharbor.com`); modeled on zingler-meats-website |
| dad-can-i-wear | "Dad, Can I Wear This?" app (compose + python) |
| flashback-martial-arts-website | client site — EmDash, scaffolded from reveal-fitness-website, live on Digital Harbor account (`flashback.mydigitalharbor.com` + `flashback-martial-arts-website.digitalharbor.workers.dev`) |
| freedomchurch-website | client site — Freedom Church Vero Beach (one-pager EmDash, cloned from tranquil-living; DH account, canonical `freedomchurch.mydigitalharbor.com`; old Radiant site stays live until cutover, `demo_mode` banner on) |
| DigitalHarbor | Digital Harbor site — Astro 7 + EmDash CMS on CF Workers (`mydigitalharbor.com`); `/sites` board backed by `src/data/sites.ts` + `OPS_DATA` |
| DigitalHarbor-markata | markata variant of DigitalHarbor |
| DigitalHarbor-template | template repo |
| hofackers-website | client site (Astro 7 + EmDash on CF Workers) — moved 2026-10-19 off its dedicated "Hofackers Farm" account (parked unused) to the shared Digital Harbor account: `hofackers-website.digitalharbor.workers.dev` + `hofackers.mydigitalharbor.com` |
| holysmokes-website | prospect demo — Holy Smokes (8-location WI/MI smoke-shop chain, pitch to switch them off a rented AMP template); EmDash on CF Workers, DH account, live at `holysmokes.mydigitalharbor.com` + `holysmokes-website.digitalharbor.workers.dev` (demo_mode on, sites.ts registered) |
| jacobs-meat-market-website | client site — Astro 7 + EmDash on CF Workers, Digital Harbor account (`jacobs.mydigitalharbor.com`); declined prospect, stays up as portfolio piece |
| olivet-website, olivet-website-emdash | client site — `olivet-website-emdash` is canonical production (`olivet.mydigitalharbor.com` on DH account; olivetbiblechurch.org cutover pending); seed markdown lives at `olivet-website-emdash/seed/content/`; `olivet-website` superseded (worker torn down 2026-10-23) — archive only: `weebly-capture/` mirror of the old Weebly site + git history (`-emdash` also holds shared `.agents/skills/{building-emdash-site,emdash-cli,creating-plugins}`) |
| power-washing-website | flagship DH demo site (Good Works — `gdwrks.com`, DH account; fictional 555 contact info since 2026-10-27; retired `personal` config removed 2026-10-23) |
| reveal-fitness-website | client site (Astro 7 + EmDash on CF Workers, `revealfitness.org`, dedicated account + `-preview` worker) |
| tranquil-living-website | client site — Tranquil Living Pathways (adult family home near Appleton WI; owner Valerie Adamski — other details unverified); static Astro + Worker `/api/contact` → Resend, DH account; **parked/offline 2026-10-25** (canonical `tranquil-living.mydigitalharbor.com` removed); cloned from claritycare-website |
| tranquil-living-website-emdash | client site — EmDash rebuild of Tranquil Living Pathways; **the dh-websites reference implementation** for the one-pager + contact-form EmDash shape (clone this for new sites); DH account |
| vans-construction-website | client site for **711 Custom Home Designs** (Josh VanStraten), Digital Harbor account (`711-designs.mydigitalharbor.com`, target domain `711chd.com` — NOT `vansconstruction.com`; legacy repo/worker slug) |
| sites-dashboard | dashboard across the sites |
| pilgrims-process-website | Pilgrim's Process book site — EmDash on CF Workers, Digital Harbor account (`pilgrims-process.digitalharbor.workers.dev`); audiobook/text/trailers seeded from `~/Downloads/ThePilgrimsProcess*` |
| zingler-meats-website | client site — Eric Zingler, deer processing ($170) + taxidermy prep ($50); static Astro + Worker `/api/contact` → Resend, DH account (`zingler-meats-website.digitalharbor.workers.dev`); modeled on power-washing-website |
| bw-lawn-website | client site — B&W Lawn Services (mow/trim/edging, flat $30/service); static Astro + Worker `/api/contact` → Resend, DH account (`bw-lawn-website.digitalharbor.workers.dev`); cloned from zingler-meats-website |
| pype.dev, pypeaday | personal blog (markata) |
| pype.dev-go | pype.dev ported to markata-go (migration workspace) |
| images.pype.dev | image repo backing pype.dev |

## Homelab

| repo | what it is |
| --- | --- |
| ansible-nas, ansible-playbooks | NAS and server automation |
| homelab-argocd | cluster GitOps |
| homelab-compose | docker-compose services |
| homelab-dev, homelab-mono | TODO: role of each |
| terraform-cloudflare-factory | per-client Cloudflare accounts IaC (`accounts/<client>/`, MinIO state at `s3.paynepride.com`, `WORKFLOW.md` + `EMDASH-DEPLOY.md`). Source its `.envrc` before any `tofu` command or the S3 backend auth fails. Also owns `workers/site-monitor` (5-min uptime probes → SigNoz; `src/sites.json` is regenerated from the registry via `scripts/export_sites.py`) and `dashboards/` (SigNoz dashboard JSON sources). Also owns `scripts/dh-site` — prospect→demo→live lifecycle CLI for lightweight DH client sites (`new <slug>` scaffolds + deploys a zingler-clone demo, `convert` demo→live, `status` shows pipeline + demo expiry; appends `registry/pipeline.jsonl` events so CRM writes can replay while ghost is down). Note the ghost coupling: MinIO state is hosted on ghost — while ghost is down, `deploy_token` minting fails and DH-site `.envrc` files can't mint `CLOUDFLARE_API_TOKEN`, so wrangler deploys fail |
| zfs-ops | ZFS replication configs + systemd timers per host |
| stable-diffusion-webui-docker | SD WebUI docker stack |

## Apps

| repo | what it is |
| --- | --- |
| cannalyze, cannalyze2 | FastAPI full-stack app |
| names-api | name meaning/origin REST API — FastAPI + Postgres on ghost, names.paynepride.com (Cloudflare worker/D1 deleted 2026-10-15) |
| soonish | **a Notifiq monorepo checkout** — misleading dir name; remote is `nic/notifiq.git` on git-ghost. FastAPI + Temporal worker + multiple frontends served from one image. Live at `app.notifiq.net` — prod is a **Komodo stack `soonish` on ghost** (`/tank/encrypted/docker/komodo-zfs/periphery/stacks/soonish`) running a hand-built `notifiq-app:dev` image, NOT the documented registry release-image flow — deployment reality drifted from the repo's deploy skill (ambitious-dirigible). Prod health is green except `/api/v1/events?upcoming` (500'd on a tz-aware/naive datetime compare during the audit; returns 200 `[]` on 2026-11-16 recheck — data-dependent). Canonical checkout; remote `nic/notifiq.git` on git-ghost |
| soonish-sh | small unrelated app scaffold (github `pypeaday/soonish-sh`, created Oct 4) |
| notifiq, notifiq-worktrees | second checkout of the same `nic/notifiq.git` monorepo + its git worktrees — **`notifiq` is a STALE pre-canonical clone** (36 commits behind `origin/main`; its own AGENTS.md still describes Temporal as required); never edit or deploy from it, `soonish` is canonical (ambitious-dirigible) |
| psychopomp | rust project |
| markata-go | Go rewrite of upstream markata — plugin-driven SSG |
| blantons-watch | Blanton's letter-set price/stock monitor on ghost (blantons.paynepride.com) |
| listener | "Article Listener" clone — URL/text → Kokoro TTS → web player + private podcast feed (listen.paynepride.com, ghost) |
| pilgrims-process | The Inquirer book project — manuscript + HyperFrames chapter trailers (videos/). Website is pilgrims-process-website |
| sermon-prep | Markdown sermon/notes app at sermons.paynepride.com (ghost, Komodo stack) — md editor, `[[` verse autocomplete (vendored BSB+KJV), present mode, print. Staple homelab app (built for Simeon Trust Nov 2026, now weekly worksheets); `scripts/publish-to-blog.py` exports a doc to pype.dev as a markata note, `export-docs.py` dumps prod; `npm test` = server smoke |
| simeon-trust-nov-2026 | **Archived 2026-11-16** — Simeon Trust workshop materials + PLAN.md (Forgejo-only); working notes live in sermon-prep under the `simeon-2026` project |
| halloween-timeline | Static interactive Halloween-history timeline ("The Long Night") at halloween.paynepride.com — nginx on ghost, Komodo stack |
| jb-sleuth | OSINT case workspace (phone/email/username footprinting — maigret/sherlock/holehe/phoneinfoga; **not git-tracked**, sensitive) + `sentinel/` subdir = buy-guide site for the client's covert camera install at sentinel-j.paynepride.com (repo `nic/jb-sleuth`, nginx on ghost, Komodo stack, no auth) |
| sentinel-vid | Reolink clip viewer for j-sentinel (house camera laptop): Go+vanilla-JS continuous timeline player at cam-j.paynepride.com (whitelist: LAN+tailnet); repo `nic/sentinel-vid`, Komodo stack `sentinel-vid` (web + rclone sftp pull from `minec@j-sentinel.tail91d75.ts.net`). Footage → `tank/encrypted/nas/sentinel-j` — **deliberately not backed up anywhere** (harbor-excluded, unlisted in vault/aurora replication + sanoid), 3.5T quota, 30d retention via the sync container |
| olivet-snow | Snow-crew scheduler for Olivet Bible Church at snow.paynepride.com (ghost, Komodo stack) — Open-Meteo-driven clearing events before Sun 07:00 / Thu 17:30 deadlines; coordinator assigns plow/blower volunteers, APP_PASSWORD cookie auth |
| pray-for-our-leaders-politics | "Pray for Our Leaders" — address → elected officials lookup; static SPA + `server.py`/`src/worker.ts` same-origin proxy for Election Wrld (keyless, POST has no CORS headers). DH-account Worker+ASSETS deploy was mid-flight 2026-11-13; county/local/school-board coverage needs a WardAtlas or Cicero key (see repo findings) |

Correction rule: keep this table one line per repo; detail belongs in each repo's own AGENTS.md.

**Not a repo:** `~/projects/personal/notes/` — loose cross-repo research/findings drop (sauna-options.md/.json, office-sauna-infrared.*, sauna-report.html). Not git-tracked; files that belong to one project still go in that repo's `docs/`.

## Twenty CRM

`twenty` MCP server = Nic's client CRM. Seeded 2026-10-05 from `sites-dashboard/src/sites.ts`. **The live client registry is now `DigitalHarbor/src/data/sites.ts`** (plus `registry/sites.yaml` in terraform-cloudflare-factory) — the dh-websites checklist updates it on every site change; sites-dashboard is deprecated (the `sites` worker was deleted 2026-10-16, superseded by the DH `/sites` page; the repo keeps registry history only). The seed created: companies + contacts + a CUSTOMER opportunity + "Website project" note per client. Jacob's Meat Market recorded as declined prospect. Digital Harbor / Good Works / 1Man1Band are Nic's own cos. Update Twenty when sites.ts gains a client.

# Projects

Inventory of `~/projects/personal/`. Read when a task names a repo you can't see, or asks which project owns something.

## Client and business websites

Most deploy to Cloudflare via `wrangler`; several carry ansible playbooks for server provisioning.

**Deploy map:** the live URL is always `https://<wrangler.jsonc "name">.<account-subdomain>.workers.dev`. Which account/subdomain each site uses lives in `terraform-cloudflare-factory/registry/sites.yaml` (and `accounts/<client>/`). Paid clients get dedicated accounts; unpaid/prospect demos share the Digital Harbor account; personal sites share `nicpayne713` — deploys use a shared personal-account token held in each site's gitignored `.envrc` (regenerate via `tofu -chdir=accounts/vans output -raw deploy_token` inside terraform-cloudflare-factory).

| repo | what it is |
| --- | --- |
| 1man1band-website | band site |
| church-calendar-homepage | church calendar site (node + compose, not wrangler) |
| dad-can-i-wear | "Dad, Can I Wear This?" app (compose + python) |
| flashback-martial-arts-website | client site — EmDash, scaffolded from reveal-fitness-website, live on personal account (`flashback-martial-arts-website.nicpayne713.workers.dev`) |
| DigitalHarbor | Digital Harbor site — Astro 7 + EmDash CMS on CF Workers (`mydigitalharbor.com`); `/sites` board backed by `src/data/sites.ts` + `OPS_DATA` |
| DigitalHarbor-markata | markata variant of DigitalHarbor |
| DigitalHarbor-template | template repo |
| hofackers-website | client site (Astro 7 + EmDash on CF Workers) — moved off its dedicated "Hofackers Farm" account to the shared Digital Harbor account: `hofackers-website.digitalharbor.workers.dev` + `hofackers.mydigitalharbor.com` |
| jacobs-meat-market-website | client site — Astro 7 + EmDash on CF Workers (declined prospect, stays up as portfolio piece) |
| olivet-website, olivet-website-emdash | client site — `olivet-website-emdash` is canonical production; `olivet-website` stays deployed as a maintained Digital Harbor demo + EmDash seed/migration source (`-emdash` also holds shared `.claude/skills/{building-emdash-site,emdash-cli,creating-plugins}`) |
| power-washing-website | client site (Good Works — `gdwrks.com`) |
| reveal-fitness-website | client site (Astro 7 + EmDash on CF Workers, `revealfitness.org`, dedicated account + `-preview` worker) |
| vans-construction-website | client site for **711 Custom Home Designs** (Josh VanStraten, target domain `711chd.com` — NOT `vansconstruction.com`; legacy repo/worker slug) |
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
| terraform-cloudflare-factory | per-client Cloudflare accounts IaC (`accounts/<client>/`, MinIO state at `s3.paynepride.com`, `WORKFLOW.md` + `EMDASH-DEPLOY.md`). Source its `.envrc` before any `tofu` command or the S3 backend auth fails. Also owns `workers/site-monitor` (5-min uptime probes → SigNoz; `src/sites.json` is regenerated from the registry via `scripts/export_sites.py`) and `dashboards/` (SigNoz dashboard JSON sources) |
| zfs-ops | ZFS replication configs + systemd timers per host |
| stable-diffusion-webui-docker | SD WebUI docker stack |

## Apps

| repo | what it is |
| --- | --- |
| cannalyze, cannalyze2 | FastAPI full-stack app |
| names-api | name meaning/origin REST API — FastAPI + Postgres on ghost, names.paynepride.com (Cloudflare worker/D1 deleted 2026-10-15) |
| soonish | **a Notifiq monorepo checkout** — misleading dir name; remote is `nic/notifiq.git` on git-ghost. FastAPI + Temporal worker + multiple frontends served from one image |
| soonish-sh | small unrelated app scaffold (github `pypeaday/soonish-sh`, created Oct 4) |
| notifiq, notifiq-worktrees | second checkout of the same `nic/notifiq.git` monorepo + its git worktrees |
| psychopomp | rust project |
| markata-go | Go rewrite of upstream markata — plugin-driven SSG |
| blantons-watch | Blanton's letter-set price/stock monitor on ghost (blantons.paynepride.com) |
| listener | "Article Listener" clone — URL/text → Kokoro TTS → web player + private podcast feed (listen.paynepride.com, ghost) |
| pilgrims-process | The Inquirer book project — manuscript + HyperFrames chapter trailers (videos/). Website is pilgrims-process-website |

Correction rule: keep this table one line per repo; detail belongs in each repo's own AGENTS.md.

## Twenty CRM

`twenty` MCP server = Nic's client CRM. Seeded 2026-10-05 from `sites-dashboard/src/sites.ts` (the client registry — source of truth): companies + contacts + a CUSTOMER opportunity + "Website project" note per client. Jacob's Meat Market recorded as declined prospect. Digital Harbor / Good Works / 1Man1Band are Nic's own cos. Update Twenty when sites.ts gains a client.

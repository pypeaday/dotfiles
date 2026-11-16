---
name: ghost-app-deploy
description: "Deploy a custom containerized app to ghost. Use when the user asks to deploy, host, or ship an app/site/service to the homelab, or a build session ends with 'deploy to ghost'. Covers Forgejo repo + image, compose stack, traefik exposure, Komodo adoption, and the pre-launch checklist."
---

# Deploy a custom app to ghost

Machine facts (Komodo adoption details, traefik API port, docker context quirks) live in `~/.config/devin/docs/ENVIRONMENT.md`; read it if a step references something unfamiliar.

## Steps

1. **Repo** — `git push` to `git-ghost:nic/<app>`; push-create makes the repo (the API can't — no token has `write:user`).
2. **Image** — copy the Forgejo Actions `docker-build-push` workflow from `nic/names-api` so pushes build and push `git.paynepride.com/nic/<app>:latest`. Build/push by hand (`docker --context ghost build/push`) only for the first bootstrap.
3. **Stack** — compose at `homelab-mono/compose/ghost/<stack>/docker-compose.yml`. `.env` gitignored, `.env.example` committed. Data under `/tank/encrypted/docker/<app>/`. Service joins `phantomlink` (external network); publish no host port.
4. **Expose** — traefik labels on the app container: `entrypoints=websecure` is required (without it the router registers on :80 only and HTTPS 404s). If the app accepts writes (settings forms, toggles, uploads), add `default-whitelist@file` or auth middleware — a public `*.paynepride.com` route with open POSTs is attack surface, and copying the house pattern without it copies the gap too.
5. **Adopt** — register the stack in Komodo (the fleet is Komodo-managed; a plain `compose up -d` leaves an unmanaged stack). `project_name` matches the live compose project, `auto_pull: false` (`:latest` surprise-recreates), `files_on_host: true` + absolute `run_directory` for file-mode stacks, `ignore_services` for one-shot jobs. Sync the compose dir to `/tank/encrypted/nas/code/homelab-compose/ghost/<stack>/`.
6. **Record** — row in `homelab-mono/compose/services.csv`; runbook in the app repo's `AGENTS.md`; `PROJECTS.md` entry. File manual follow-ups via the task-management skill.

## Verify

- Hit `/healthz` (or root) on the container's `phantomlink` IP first, then the public hostname — that separates app-down from routing-down.
- For a traefik 404 on a new route: check `http://ghost:8083/api/http/routers` (missing/disabled router ≠ app down), then re-run the **original** failing request before naming a cause. "Registration lag" is a guess until that request passes.
- Test outbound HTTP / scrapers **from inside the deployed container**, not just the dev box — egress IP and TLS fingerprint differ by host. If a target 403s every Python client (`httpx`, `curl_cffi`), try plain `curl -sfL` as a subprocess before UA games; some WAFs pass it.
- Smoke-test writes get undone in the same step, or run against a throwaway DB — a verification write left behind becomes false state the user trusts.
- Don't `docker exec` ad-hoc Python inside a running scheduler app to trigger work — it races the in-process scheduler (double alerts, split state). Give monitor-style apps `/poll` and `/test-alert` HTTP endpoints instead.

## Conventions

- Creds come from the service's own UI or REST API — never write a token into a live app's DB from a root container (skips validation, no audit trail).
- Never echo tokens to stdout, and never put them in URL query strings — clients log full URLs. Header auth where supported (`X-Gotify-Key` for gotify).
- Alerts: POST `http://gotify:80/message` on `phantomlink` with `X-Gotify-Key`.
- All docker ops go through `docker --context ghost`; never `docker logs --since` (unrotated multi-GB logs).

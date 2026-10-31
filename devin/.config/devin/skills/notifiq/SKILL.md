---
name: notifiq
description: "Work in Notifiq (app.notifiq.net) — the user's notification/reminder service. Use when sending notifications, creating or managing channels (sms/email/gotify/ntfy), creating events or reminders, subscribing to events, or checking what's scheduled. Notify = POST to a named channel; reminders = events + subscriptions."
---

# Notifiq

User's notification service. Prod API: `https://app.notifiq.net` (self-hosted
on ghost; repo `~/projects/personal/soonish`, remote `nic/notifiq`).

## Auth

API token (durable `soonish_*`, survives restarts) lives in
`~/.config/notifiq/config`:

```
base_url=https://app.notifiq.net
token=soonish_...
```

Already present on this machine — agents can use it as-is. Revocable via
`DELETE /api/v1/tokens/{id}`. JWT logins are NOT durable (SECRET_KEY rotates
on redeploy); always use the API token.

## CLI

`uv run notifiq ...` — must run inside `~/projects/personal/soonish/backend`
(the CLI is `backend/src/cli`, only exists in a checkout). Flags `--url`,
`--token`, `--config`, or env `NOTIFIQ_BASE_URL` / `NOTIFIQ_TOKEN` /
`NOTIFIQ_CONFIG`.

```
uv run notifiq whoami
uv run notifiq channels list
uv run notifiq channels types                    # config schema per type
uv run notifiq channels create <name> --type <t> --config-json '{...}' --tag <tag>
uv run notifiq channels delete <id> --force
uv run notifiq events list [--upcoming] [--source X]
uv run notifiq events create "name" --start "1h" --end "3h" --tags "default" --source X
uv run notifiq events show <id> / events delete <id>
uv run notifiq notify "title" --body "..." --channel <name>   # one-off send
```

Times accept ISO or relative (`now`, `30m`, `1h`, `2d`).

## Raw API (when CLI lacks a verb — e.g. subscriptions)

```
TOKEN=$(grep '^token=' ~/.config/notifiq/config | cut -d= -f2)
curl -s https://app.notifiq.net/api/v1/subscriptions \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"event_id":1,"channel_ids":[1,3],"reminder_offsets":[900,3600]}'
```

- `reminder_offsets` = seconds before `start_date`.
- `PATCH /api/v1/subscriptions/{id}` replaces selectors + offsets.
- `POST /api/v1/channels/{id}/test` sends a test notification — see warning below.

## Channel config shapes (for `--config-json`)

| type | config |
|---|---|
| `gotify` | `{"server_url":"https://gotify.paynepride.com","token":"<app-token>","priority":"low|normal|high"}` |
| `email` | `{"to_email":"x@y"}` (sends via service SMTP = Resend) |
| `sms` | `{"phone_number":"3193895740","carrier":"verizon"}` (carrier email gateway via service SMTP) |
| `ntfy` | `{"server_url":"https://ntfy.sh","topic":"my-topic","priority":1-5}` |

`channels types` returns the live schema for all ~12 types.

## autosub tags

An event tagged `foo` auto-creates subscriptions on every channel tagged
`autosub:foo` (service: `src/api/services/auto_subscribe.py`). User's three
channels are all `autosub:default` → tag events `default` to notify all three.
No tag = no auto-subscription; subscribe explicitly via API.

## User's live channels (as of 2026-10-25)

`phone` (sms→vzwpix), `email` (→pm.me), `gotify` (app "Notifiq") — all
`autosub:default`, all verified with a real test send.

## Gotchas

- `POST /channels/{id}/test` currently tests **all** the user's channels and
  **echoes full apprise URLs including secrets** in the response — don't paste
  that output anywhere public. Filed as a known wart.
- Channel `config_json` is encrypted at rest with `ENCRYPTION_KEY`; the stored
  apprise URL bakes in SMTP settings at create time — change `SMTP_*` →
  recreate the channel (delete + create), don't just restart.
- Prod SMTP = Resend (`smtp.resend.com:587`, STARTTLS; port 465 does NOT work
  with apprise `mailtos`). `SMTP_FROM=noreply@notifiq.net`.
- `sms` carrier gateways deliver as MMS/email-SMS — Verizon = vzwpix.com.
- `is_admin` doesn't exist; admin surface is route-level. `tier` is dormant
  (`free` for everyone, billing disabled).
- Prod still runs Temporal for scheduling (main branch); a DB-scheduler
  rewrite exists on worktree `agent/diy-scheduler`. Doesn't matter for API use.

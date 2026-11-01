---
name: actual-finance
description: Household finance work on the user's self-hosted Actual Budget — balances, categorization, imports, spending analysis, the live dashboard, and income/burn questions. Use for any "budget", "Actual", "spend", "category", "income", "bank import", "529", "payee", or household-money task, including new sessions that need the current numbers.
---

# Actual finance skill

The user runs self-hosted Actual Budget for household finance. Two docs
carry the durable knowledge — **read them before doing money work**:

- `~/projects/personal/homelab-mono/compose/ghost/actual/FINANCE.md` —
  the numbers: account balances + anchors, income sources, burn structure,
  category conventions, anomalies, decisions log. Update it when facts change.
- `~/projects/personal/homelab-mono/compose/ghost/actual/README.md` —
  ops: deploy, importer, sync recovery, safe bulk-delete recipe, OOM gotchas.

## Where things live

- App: https://actual.paynepride.com · dashboard: https://budget.paynepride.com
- Server + importer + dashboard run on ghost (`docker --context ghost`,
  network `phantomlink`; dashboard source in the actual dir above).
- Read-only query db: `docker --context ghost exec actual-dash node -e …`
  with `/cache/My-Finances-cb746f6/db.sqlite` + better-sqlite3 inside the
  dash image (path in FINANCE.md cookbook).

## Hard rules (learned from a real corruption incident)

- **Never write sqlite directly** — mutations go through `@actual-app/api`
  in a one-off container so they emit sync messages. Raw writes never sync.
- **Never delete transfer-linked rows before severing both ends**
  (payee + `transferred_id`) — cascades and mirror spawns. Recipe in README.
- Big mutation runs go in an **unconstrained one-off container** (640m
  dash limit OOMs past ~2k ops).
- Treat `Rebaseline Transfer` payee + `Starting Balances` cat as artifacts,
  not spending. Card OBs are *implied* — don't report them as bank-verified.
- October/partial months are not full months; say so.

## Money model (details in FINANCE.md)

- Income: Caterpillar only, ~$9k/mo (Avant ended ~Apr-2026); Cat bonus ~Mar/Apr.
- Recurring burn ~$11.3k/mo → structural deficit ~$2–4k; dashboard's
  "burn structure" panel shows fixed/giving/movable bands.
- `Amazon` category = review staging — match against Amazon order history
  before recategorizing; recurring identical amounts are Subscribe & Save.
- Categories mean specific things (FINANCE.md conventions) — e.g. `Cash`
  for ATM, `Bills` includes the Hall Block phone reimbursement.

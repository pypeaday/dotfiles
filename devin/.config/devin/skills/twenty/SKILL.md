---
name: twenty
description: "Work in the user's self-hosted Twenty CRM (crm.paynepride.com). Use when adding or updating CRM records (companies, people, opportunities, notes), logging calls/emails/activity, querying customer data, clearing workspace seed/demo data, or operating on a specific workspace (Digital Harbor, Good Works, Notifiq). Customer source of truth: sites-dashboard/src/sites.ts + each site repo."
---

# Twenty CRM

Self-hosted Twenty v2 at `https://crm.paynepride.com`, multi-workspace enabled.
Stack runs on ghost (`homelab-compose/ghost/twenty`); each workspace gets
`<subdomain>.crm.paynepride.com` — see `homelab-mono/compose/ghost/twenty/README.md`
for the Traefik rule that must name each new subdomain. Live route file is the
mounted `/tank/encrypted/docker/traefik/config.yml` on ghost (in-place write —
the bind mount pins the inode); mirror edits into the repo copy. Subdomain
rename = `update core.workspace set subdomain=...`.

## Access routes — pick by workspace

The MCP `twenty` server (`https://crm.paynepride.com/mcp`, key at
`~/.local/share/devin/twenty-api-key`) is scoped to ONE workspace:
**Digital Harbor**. API keys are per-workspace; a key minted in workspace A
cannot touch workspace B.

- **Digital Harbor ops** → use the `twenty` MCP tools.
- **Other workspaces** → mint a key in that workspace (Settings → APIs &
  Webhooks → + API key), or act on the DB directly (below).

Known workspaces (postgres `default` db):

| Workspace | ID | Subdomain | Schema |
|---|---|---|---|
| Digital Harbor | a5bd5bec-4ccb-49b2-a6e8-04d38a06a621 | dh | workspace_9t8lk0h07h3s06z0fy3gl242p |
| Notifiq | 87adc530-5ce6-4b2a-a1c5-8f8f515e680d | notifiq | workspace_8164wxjd4id7y6l2cas2ee58t |
| Good Works | ebcd0f16-6826-4bd2-92d0-19b3cad6e58d | gdwrks | workspace_dyk5bis6fc162y3jyvn9xa3kd |

`core.dataSource` is empty — identify a schema by row `createdAt` timestamps
or record contents, not by lookup.

## MCP call pattern

1. `learn_tools(toolNames: [...])` — fetch schemas first; built names like
   `find_many_companies` resolve or come back with closest matches.
2. `execute_tool(toolName, arguments)` — CRUD grammar:
   `find_many_{objects}` | `find_one_{object}` | `create_one/many_{object}` |
   `update_one_{object}` | `delete_many_{objects}`.
3. `find_many_*` requires `select` (field names or `"*"`) and takes top-level
   filters (`{ name: { ilike: "%x%" } }`, `and`/`or`/`not` combinators).
   Composite fields filter by sub-field; check `hasNextPage` before
   concluding a record is absent.

## Field shapes (v2)

- Person: `name {firstName, lastName}`, `emails {primaryEmail, additionalEmails[]}`,
  `phones {primaryPhoneNumber, primaryPhoneCountryCode, primaryPhoneCallingCode}`,
  `companyId`, `jobTitle`.
- Company: `domainName {primaryLinkUrl, primaryLinkLabel, secondaryLinks[]}`,
  `address {addressStreet1, addressCity, addressPostcode, ...}`.
- Notes/tasks are unattached until linked: `create_one_note` then
  `create_many_note_targets` with `targetPersonId` / `targetCompanyId` /
  `targetOpportunityId`.
- `position` is required on creates — `"last"` appends.

## Log an email/call manually

`update_one_person` with `lastContactAt` + `lastOutboundAt` (inbound:
`lastInboundAt`), then `create_one_note` + `create_many_note_targets` on the
person AND company. (Real auto-sync needs Google/Microsoft in Settings →
Accounts; Proton isn't supported natively.)

## Deletes

Delete tools **soft-delete** (`deletedAt`) — records stay recoverable in the
UI trash. For seed-data cleanup via SQL, set `"deletedAt" = now()` on
`company`, `person`, `opportunity`, `dashboard` by exact id. Never touch
`workspaceMember`, `objectMetadata`, `fieldMetadata`, `view*` — they define
the workspace itself.

DB access (fresh workspaces have no API key):

```bash
ssh ghost 'docker exec -i twenty-db psql -U postgres -d default -f -' < script.sql
```

## New workspace seed data

A fresh workspace seeds 5 demo companies (Notion, Stripe, Figma, Airbnb,
Anthropic), 5 demo people (their CEOs), 6 opportunities, 1 "My First
Dashboard". Clean = soft-delete all of those; nothing else is seeded.

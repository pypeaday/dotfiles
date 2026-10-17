# Dreaming — research notes

Research on Anthropic's "dreaming" feature for Claude Managed Agents, from primary
sources (docs, API reference, launch blog, Code w/ Claude talk transcript).
Compiled 2026-10-14; dreaming is a **research preview** (request access —
https://claude.com/form/claude-managed-agents), and Anthropic warns request/response
shapes are volatile with no deprecation period
(https://platform.claude.com/docs/en/api/beta/dreams).

## Sources

- Dreams guide: https://platform.claude.com/docs/en/managed-agents/dreams
- Dreams API reference: https://platform.claude.com/docs/en/api/beta/dreams
- Memory guide: https://platform.claude.com/docs/en/managed-agents/memory
- Scheduled deployments: https://platform.claude.com/docs/en/managed-agents/scheduled-deployments
- Launch blog: https://claude.com/blog/new-in-claude-managed-agents
- Talk "Memory and dreaming for self-learning agents" (Mahesh Murag, Anthropic PM,
  Code w/ Claude 2026): https://www.youtube.com/watch?v=RtywqDFBYnQ —
  transcript https://www.usetranscribe.io/yt/RtywqDFBYnQ/memory-dreaming-agents
- Session page: https://claude.com/code-with-claude/session/sf-memory-and-dreaming-for-self-learning-agents
- Prior art, Letta/UC Berkeley "Sleep-time Compute": https://arxiv.org/html/2504.13171 ,
  https://www.letta.com/blog/sleep-time-compute/

## Overview

- Agents write to memory stores as they work, but writes are "local and incremental":
  over many sessions a store accumulates duplicates, contradictions, and stale entries.
  A dream is a cleanup/synthesis pass: it reads an existing memory store plus past
  session transcripts and produces a **new, reorganized memory store** — duplicates
  merged, stale/contradicted entries replaced with the latest value, new insights
  surfaced. (dreams guide)
- The input store is **never modified** by default, so the output can be reviewed and
  discarded. (dreams guide)
- Blog framing: "a scheduled process ... that reviews agent sessions and memory
  stores, extracts patterns, and curates memories so agents improve over time. You
  decide how much control you want: dreaming can update memory automatically, or you
  can review changes before they land." (blog)
- Positioned as one half of a memory system: "Memory lets each agent capture what it
  learns as it works. Dreaming refines that memory between sessions, pulling shared
  learnings across agents." (blog)

## How a dream works (inputs / outputs / lifecycle)

A dream is an **asynchronous job** (`drm_...`) that takes two kinds of input
(dreams guide, API ref):

- **Inputs** — exactly one `memory_store` entry + exactly one `sessions` entry:
  - `{"type": "memory_store", "memory_store_id": "memstore_..."}` — the store to
    verify, dedupe, and reorganize. Must be in the same workspace, must not be archived.
  - `{"type": "sessions", "session_ids": ["sesn_...", ...]}` — **1 to 100** session
    transcripts (no duplicates, same workspace) mined for patterns/insights.
  - No existing store? Create an empty memory store first and pass it as input
    (dreams guide tip).
- **Output** — a *separate* memory store that starts as a clone of the input. The
  output store ID appears in the dream's `outputs` array shortly after status becomes
  `running` (once the workflow clones the input); a `running` dream can briefly report
  an empty `outputs`. With `output_behavior: update_existing` the result is written
  into the input store instead (API ref).
- **Lifecycle** (`status`): `pending` → `running` → `completed` | `failed` | `canceled`.
  `usage` token counts update while running. `failed`/`canceled` leave the output
  store as-is with partial contents for inspection. (dreams guide)
- **Duration**: "typically minutes to a few hours, driven by the number of input
  transcripts." Cost ≈ linear in number/length of sessions; billed at standard token
  rates for the chosen model. Docs recommend starting with a small batch. (dreams guide)
- **Observability**: once `running`, `dream.session_id` points at the real session
  executing the pipeline — you can stream its events to watch what the dream reads and
  writes; the session is archived (kept) when the dream finishes. In the talk demo the
  dream session spins up subagents that comb transcripts. (dreams guide; transcript ~20:47)
- **Polling**: `GET /v1/dreams/{id}` until `completed`/`failed`/`canceled` (~10s
  interval in examples). No webhook for dreams in the docs; webhooks were launched for
  session completion. (dreams guide, blog)

## The memory store it curates

From the memory guide (https://platform.claude.com/docs/en/managed-agents/memory):

- A **memory store** is a workspace-scoped collection of text documents "optimized for
  Claude." Attached at session creation in `resources[]`; mounted in the sandbox as a
  directory under `/mnt/memory/<slug>`; the agent reads/writes it with ordinary file
  tools (bash/grep/edit). A mount description is auto-added to the system prompt.
- Each **memory** is a file addressed by path; CRUD via
  `/v1/memory_stores/{id}/memories` or the Console. Caps: 100 kB (~25k tokens) per
  memory, **10,000 memories per store** — "many small focused files, not a few large."
- **Access control**: `read_write` (default) or `read_only`; enforced at the
  filesystem level. Warning: with untrusted input, prompt injection could poison a
  read_write store that later sessions trust — use `read_only` for reference stores.
  Max **8 stores per session**; common pattern is one shared read-only store
  (standards/runbooks) plus a per-user/team/project read-write store.
- **Versioning**: every mutation creates an immutable **memory version** (`memver_...`)
  — audit trail + point-in-time recovery. Versions live on the store (survive memory
  deletion), retained 30 days (recent versions of live memories kept regardless).
  `redact` endpoint scrubs content from history (secrets/PII) while keeping the audit
  metadata; can't redact the live head version. No restore endpoint — read a version
  and write its content back.
- **Concurrency**: update accepts a `content_sha256` precondition (optimistic
  concurrency) so concurrent agents don't clobber each other.
- **Store lifecycle**: create → attach at session creation only (can't add to a
  running session) → archive (one-way, read-only, can't attach to new sessions) or
  delete. On self-hosted sandboxes a worker syncs a local copy every ~15s instead of a
  live mount.
- **Header gotcha**: memory-store calls use `anthropic-beta: agent-memory-2026-07-22`;
  sending it *together with* `managed-agents-2026-04-01` returns 400. Session
  endpoints (incl. attaching stores) still use `managed-agents-2026-04-01`.
- The memory guide itself recommends dreaming as the fix when a store fills up or
  fragments: "run a dreaming session, which consolidates fragmented content into a
  separate new output store... Switch your sessions over to that output store, then
  archive or delete the original."

## What patterns it surfaces

- Blog: "patterns that a single agent can't see on its own, including **recurring
  mistakes, workflows that agents converge on, and preferences shared across a team**.
  It also restructures memory so it stays high-signal as it evolves."
- Talk (transcript ~12:44): "looks for common mistakes, things that a bunch of agents
  are doing like a failed tool call, or strategies that are working out for them."
- Demo example (transcript ~21:35–22:59): the dream noticed every SRE agent was
  triggered exactly 60s after a CPU spike → inferred inefficient retry logic, left a
  note; consolidated 5 duplicate entries into one; removed a stale entry contradicted
  by a transcript; added a **verification note** ("at this time, based on this
  transcript, this memory is accurate — you can rely on it").
- Results claimed: Harvey saw ~6× completion-rate increase on a legal benchmark
  (blog + talk ~11:29). Rakuten: 90% drop in first-pass mistakes from the memory
  system generally (talk ~3:22).

## Control / review model

- Default `output_behavior` is `create_new`: input untouched, output is a new store
  you review (Memory Stores API or Console), then **adopt** by attaching to future
  sessions in place of/alongside the old store, or **discard** (delete/archive).
  (dreams guide, API ref)
- `output_behavior: update_existing` writes the result directly into the input store
  — the "update memory automatically" path from the blog. Requires a credential
  allowed to write memory stores (403 otherwise); a second `update_existing` dream on
  the same store while one is still stopping returns 409. (API ref)
- The talk describes producing "a diff — a set of updated files" in the Console UI,
  and "you can apply it immediately... or run some checks and do manual review via the
  API." (~12:44, ~21:35)
- Safety rails: a dream never deletes/modifies its inputs. Archiving/deleting an input
  store or deleting an input session mid-run fails the dream
  (`input_memory_store_unavailable` / `input_session_unavailable`). (dreams guide)
- `instructions` (≤4,096 chars) steers the pipeline: focus areas ("focus on
  coding-style preferences"), content to preserve, output conventions. It's applied
  throughout the pipeline (what to read closely, merge/drop, how to structure output).
  It's a **synthesis pass, not a line editor** — directives like "change sentence X to
  Y" do nothing; use the Memories API for targeted edits. (dreams guide)

### Scheduling / cadence

- There is **no Anthropic-side automatic cadence** — you trigger dreams. Per the talk
  (~12:04): "kick off dreaming periodically using our console or API on kind of a cron
  basis, or plug it into an existing process — some customers kick off dreaming once
  their agents have finished a task and are spinning down." A different transcript of
  the same session phrases it "ad hoc, nightly, hourly, or triggered by events like
  the end of a session — all controlled via API"
  (https://rewiz.app/channels/@claude/memory-and-dreaming-for-self-learning-agents).
- For cron scheduling of the surrounding agent work there's a separate **scheduled
  deployments** API (`/v1/deployments?beta=true`, cron expression + timezone,
  minute granularity) — it launches sessions on a schedule; a deployment event or a
  wrapper job could then create the dream. (scheduled-deployments doc)
- The blog's phrase "scheduled process" refers to this developer-controlled cadence,
  not an Anthropic-run batch.

## API specifics

- Endpoint base: `https://api.anthropic.com/v1/dreams`. Operations:
  `POST /v1/dreams` (create), `GET /v1/dreams/{id}` (poll), `GET /v1/dreams` (list,
  `limit`≤100 + `page` cursor, `include_archived`), `POST /v1/dreams/{id}/cancel`,
  `POST /v1/dreams/{id}/archive`. (API ref)
- **Beta headers**: `anthropic-beta: managed-agents-2026-04-01,dreaming-2026-04-21`
  on dream endpoints — `managed-agents-2026-04-01` alone does NOT grant dream access.
  SDKs set these automatically. Plus `anthropic-version: 2023-06-01`. (dreams guide)
- **Models** (dreams guide limits table): `claude-opus-5-5`, `claude-fable-5-1`,
  `claude-opus-5`, `claude-fable-5`, `claude-opus-4-8`, `claude-opus-4-7`,
  `claude-sonnet-5-5`, `claude-sonnet-5`, `claude-sonnet-4-6`. `model` accepts an ID
  or `{id, speed}` — but `speed` can only be `"standard"`.
- **Limits**: 100 sessions/dream; `instructions` ≤ 4,096 chars; standard rate limits
  on creation during preview.
- **Error codes**: `timeout`, `internal_error`, `memory_store_org_limit_exceeded`,
  `input_memory_store_too_large`, `input_memory_store_unavailable`,
  `input_session_unavailable`.
- **Cancel/archive semantics**: cancel is immediate + idempotent on `canceled`;
  canceling `completed`/`failed` → 400. Archive only on terminal states (400
  otherwise), one-way, hides from default list; doesn't touch the output store.
- Create example (dreams guide):

```bash
curl -s https://api.anthropic.com/v1/dreams \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: managed-agents-2026-04-01,dreaming-2026-04-21" \
  -H "content-type: application/json" \
  --data @- <<EOF
{
  "inputs": [
    { "type": "memory_store", "memory_store_id": "$store_id" },
    { "type": "sessions", "session_ids": ["$session_a", "$session_b"] }
  ],
  "model": "claude-opus-5-5",
  "instructions": "Focus on coding-style preferences; ignore one-off debugging notes."
}
EOF
```

```python
# create + poll + adopt
dream = client.beta.dreams.create(
    inputs=[
        {"type": "memory_store", "memory_store_id": store_id},
        {"type": "sessions", "session_ids": [session_a, session_b]},
    ],
    model="claude-opus-5-5",
    instructions="Focus on coding-style preferences; ignore one-off debugging notes.",
)
while dream.status in ("pending", "running"):
    time.sleep(10)
    dream = client.beta.dreams.retrieve(dream.id)

output_store_id = next(
    o.memory_store_id for o in dream.outputs if o.type == "memory_store"
)
session = client.beta.sessions.create(
    agent=agent_id,
    environment_id=environment_id,
    resources=[{"type": "memory_store", "memory_store_id": output_store_id}],
)
```

## Design philosophy (from the talk)

Speaker: Mahesh Murag, PM on Anthropic's platform team (worked on MCP, Skills).

- **Memory is "the next primitive"** after MCP (tools), harnesses (Claude Code/agent
  SDK), Skills (Oct) — what's still unsolved is "continuous self-learning and context
  management over long-horizon tasks." (~1:26–2:08)
- **Memory as a filesystem the model manages itself**, not a constrained tool schema:
  earlier attempts (CLAUDE.md, the SDK memory tool) overspecified structure. "Agents
  can manage a virtual environment and their own file system, so why can't we go the
  same direction with memory?" Claude uses bash/grep; Opus 4.7 is SOTA at deciding
  what to store and how to structure it. (~4:20–5:42)
- **Three layers** of a frontier memory system: *storage* (attribution metadata),
  *structure/content* (files; skills framed as "a form of procedural memory"),
  *process* (what triggers updates, from which sources — dreaming lives here). (~9:26)
- **Why a separate offline process**: individual agents updated memory "in a locally
  optimal way, but it wasn't globally optimal" — sessions missed learnings other
  sessions had already figured out, repeated shared mistakes, and maintained the store
  inefficiently because they're "siloed into the specific task." (~10:32–11:29)
- **Benefits of out-of-band**: (a) cross-agent/cross-session view finds patterns a
  single agent can't see; (b) separates the *memory-quality* objective from the
  *task-completion* objective — agents need discrete, clear objectives; (c) zero
  latency on the hot path. (~13:10–14:45)
- **Compute framing**: dreaming applies "scaling laws of using additional compute" to
  memory upkeep — like test-time compute for reasoning, and like a **search index**:
  upfront effort produces a curated, high-quality store that downstream agents read
  cheaply; cost amortized across all readers. (~15:30–16:58)
- **Skills tie-in**: skills are described as procedural memory with a lightweight
  spec; the dream pipeline itself curates the declarative file-store. No claim that
  dreaming generates skills in this talk. (~9:57)
- Goal: "the next day's agents automatically get better based on the learnings of the
  previous day's experience" — dreaming as a *feedback loop*: "agents write memories,
  dreaming refines, repeat." (~13:10)

## Prior art: sleep-time compute

- Letta (MemGPT team) + UC Berkeley, "Sleep-time Compute: Beyond Inference Scaling at
  Test-time" (arXiv 2504.13171): run inference *between* interactions — while the
  agent is idle — to pre-process raw context into "learned context"; ~5× test-time
  compute reduction and better accuracy when queries are predictable.
  https://arxiv.org/html/2504.13171 , https://www.letta.com/blog/sleep-time-compute/
- Letta has since shipped a `dreaming` agent option: background subagents review
  recent conversations, consolidate lessons, update memory; triggers on step-count or
  context compaction (https://docs.letta.com/agent-sdk/memory/).
- Anthropic's framing echoes it without citing it: Mahesh's analogy is *test-time
  compute* ("spend more tokens → better outcomes") applied to memory maintenance, plus
  the search-index analogy. Same core bet: offline compute on transcripts produces
  better curated state than inline writes alone.

## Key takeaways for building this yourself

- **Immutable input, curated output**: never let the batch job mutate the live store —
  clone it, write results to the clone, and make adoption an explicit swap (attach the
  new store / pointer flip). Cheap rollback = review becomes safe by default.
- **Two write paths, two objectives**: fast path — agents append local, incremental
  memories inline while working; slow path — an offline job owns global quality
  (dedup, contradiction resolution, verification notes, restructuring). Don't ask the
  task agent to also be the librarian.
- **Transcripts are the real signal**: the memory files tell you what agents *chose*
  to record; transcripts tell you what actually happened (failed tool calls, retries,
  repeated mistakes across agents). Feed both into the consolidation job.
- **Batch over N sessions, not per session**: patterns like "every agent hits this
  60s retry" only exist *across* transcripts. A per-session memory flush can't find
  them. Cap the batch (Anthropic: 100 sessions) and let cost scale ~linearly.
- **Steerable synthesis, not surgical edits**: a single natural-language
  `instructions` field applied across the whole pipeline works; line-level directives
  don't. Keep a direct CRUD API for targeted fixes.
- **Filesystem-shaped memory**: plain files + paths + bash/grep beat rigid schemas —
  modern models are already good at organizing hierarchies, and diffs/versioning come
  free (immutable versions + content-hash optimistic concurrency + attribution).
- **Make the job itself observable**: implement the dream as an ordinary agent session
  (with subagents) whose events you can stream and whose transcript persists —
  debugging "why did it merge those?" = read its transcript.
- **Human control dial**: default output to a reviewable artifact (diff/new store);
  offer an `update_existing`-style auto-merge only as opt-in, guarded (409 on
  concurrent runs, 403 without write creds). Cadence is caller-controlled: cron,
  event hook on session end, or ad hoc.

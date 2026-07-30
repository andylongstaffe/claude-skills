---
name: reflect
description: Use at the end of a session or at a natural breakpoint to capture lessons learned (mistakes, corrections, architectural patterns, workflow insights) into the user-level three-tier memory store. Triggers on "/reflect", "reflect on this", "capture lessons", "what did we learn".
---

# Reflect — capture lessons into user-level memory

Review the current conversation and distil durable lessons into the user-level
store at `~/.claude/memory/`. NEVER write a file before the user approves it.

## Store layout (three tiers)

- **Tier 1 — `~/.claude/memory/MEMORY.md`** — the always-loaded index. One line
  per Tier-2 file, scope-prefixed:
  `- [<scope>] [Title](relpath.md) — one-line headline`
- **Tier 2 — on-demand files** (each gets a Tier-1 index line):
  - Short memory → flat `~/.claude/memory/<slug>.md`
  - Topic (detailed/structured, too big for one line) →
    `~/.claude/memory/topics/<slug>.md` with `type: topic`
- **Tier 3 — `~/.claude/memory/transcripts/<YYYY-MM-DD>.md`** — append-only
  provenance notes. NOT indexed, never auto-loaded. Write here only when the
  review surfaces something worth recording that is not itself a reusable
  memory/topic.

## Scope

Each Tier-2 file and its index line carries a scope:
- `global` — cross-repo lesson, surfaces everywhere.
- `<owner>/<repo>` — repo-specific. Derive from the current repo:
  `git remote get-url origin`, strip `.git`, take the last `<owner>/<repo>`
  segments (e.g. `calculi-corp/policy-service`). If there is no usable remote,
  the lesson can only be `global` (repo-scoped lessons need a remote).

## Frontmatter for Tier-2 files

```markdown
---
name: <short title>
description: <one line — reused as the index headline and for recall relevance>
type: feedback | project | reference | topic
scope: global | <owner>/<repo>
---
<body>
```
For `feedback`, follow the body with `**Why:**` and `**How to apply:**` lines.
Link related entries with `[[other-slug]]`.

## Procedure

1. **Scan the conversation** for: mistakes made, corrections the user gave,
   architectural patterns worth reusing, workflow lessons. Skip anything the
   repo/CLAUDE.md/git history already records, and anything that only mattered
   to this one conversation.
2. **Classify each candidate into a tier:**
   - short, single fact → Tier-2 short memory
   - detailed/structured knowledge → Tier-2 topic
   - notable provenance, not reusable as a memory/topic → Tier-3 transcript
3. **Dedup first.** Read existing `~/.claude/memory/*.md` and
   `~/.claude/memory/topics/*.md`. If a candidate overlaps an existing entry,
   propose UPDATING that file rather than creating a near-duplicate.
4. **Determine scope** per candidate (global vs current repo).
5. **Present all candidates to the user** — for each: tier, scope, proposed
   filename, and the full proposed content. WAIT. The user may edit, reject,
   reclassify, or approve each. Write NOTHING before approval.
6. **On approval, per approved candidate:**
   - Short memory / topic: write/update the file (frontmatter incl. `type`,
     `scope`); add or refresh its `MEMORY.md` index line, scope-prefixed.
     Topics live under `topics/` so their index relpath is `topics/<slug>.md`.
   - Transcript: append a dated section to
     `~/.claude/memory/transcripts/<YYYY-MM-DD>.md`. Do NOT add an index line.
7. **Keep the index small** (Tier 1 target < 500 lines). If it is growing,
   flag candidates for consolidation rather than piling on near-duplicates.

## Recall (context)

A SessionStart hook (`reflect-recall.sh`) injects scope-matched index lines into
new sessions, controlled by `CLAUDE_REFLECT_RECALL` (`index` default | `bodies` |
`off`). You do not invoke recall — you only write what it later surfaces. Writing
a good one-line `description` matters: it IS the index headline the hook emits.

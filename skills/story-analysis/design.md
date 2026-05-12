# Story Analysis Skill — Design Spec

Date: 2026-05-12

## Purpose

A skill that analyses Jira epics/solutions against product documentation and existing codebase, with the goal of identifying gaps and proposing user stories grounded in full context.

## Modes

### Mode 1: Analyse/Critique

Invoked with: `/story-analysis CBP-12345`

Output: Structured analysis only — ambiguities, gaps, scope risks, contradictions, what's already built vs net-new.

### Mode 2: Analyse + Propose Stories

Invoked with: `/story-analysis CBP-12345 --propose`

Output: Same analysis as Mode 1, plus proposed user stories in `user-story` skill format. On user approval, creates stories in Jira linked to the parent epic.

## Workflow Steps

1. Read `docs/product-context.md` from the policy-service repo for entry points
2. Fetch the Jira issue (epic/solution) via Atlassian MCP — extract title, description, acceptance criteria, links
3. Fetch team home page descendants → identify relevant child pages (Reqs, Design folders) based on epic keywords/theme
4. Fetch the "Useful docs" aggregator page → list external docs, flag unfetchable ones (Google Docs, Whimsical) — ask user to provide excerpts if relevant
5. Scan codebase:
   - `plans/` — point-in-time context only (useful for understanding intent/decisions, NOT authoritative on current state)
   - `docs/` — living documentation
   - `internal/` — actual implementation (source of truth for what's built)
6. Synthesise into structured analysis:
   - Summary of the epic/solution
   - Relevant context gathered (which docs, which code)
   - Gap analysis: what's unclear, missing, contradictory
   - Scope assessment: what's already done, what's net-new
   - Risks or open questions
7. If `--propose` mode: generate user stories using `user-story` skill format, grouped logically
8. On user approval: create stories in Jira via MCP, linked to parent epic, with team field set

## Reference File

Lives at: `docs/product-context.md` (in policy-service repo, checked into version control).

```markdown
# Product Context

## Confluence (SDP space)
- Team home: https://cloudbees.atlassian.net/wiki/spaces/SDP/pages/5148770323 (root — navigate children for requirements, designs, analysis)
- Useful docs (aggregator): https://cloudbees.atlassian.net/wiki/spaces/SDP/pages/6212517970
- Analysis plans: https://cloudbees.atlassian.net/wiki/spaces/SDP/pages/6353518688

## Jira
- Project: CBP
- Board: https://cloudbees.atlassian.net/jira/software/c/projects/CBP/boards/4916
- Team filter: "CBP Policy Engine"

## Codebase
- Plans: plans/ (point-in-time, may be outdated)
- Design specs: docs/
- Implementation: internal/
```

## Delegation

- Story formatting: follows `user-story` skill rules
- Jira field conventions: from CLAUDE.md (team field ID, AC in ADF format, etc.)

## What the Skill Does NOT Do

- Auto-create anything in Jira without explicit user approval
- Fetch every linked doc — only ones relevant to the specific epic
- Assume external docs (Google Docs, Whimsical) are accessible — asks user for content
- Treat plans/ as current state — uses codebase and Jira as source of truth

## Artefacts to Create

1. `/Users/alongstaffe/.claude/skills/story-analysis/SKILL.md` — the skill itself
2. `docs/product-context.md` — reference file in policy-service repo

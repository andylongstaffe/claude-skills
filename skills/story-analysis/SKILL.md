---
name: story-analysis
description: Use when asked to analyse a Jira epic/solution, review against product documentation, or propose user stories from an epic. Triggers on "analyse this epic", "review this solution", "propose stories for", "story-analysis".
---

# Story Analysis

Analyse Jira epics/solutions against product documentation and existing codebase. Two modes:

- **Analyse only** (default): structured critique — gaps, ambiguities, scope risks, what's done vs new
- **Analyse + propose** (`--propose`): same analysis, plus proposed user stories ready for Jira creation

## Invocation

- `/story-analysis CBP-12345` — analyse only
- `/story-analysis CBP-12345 --propose` — analyse and propose stories
- If no ticket number provided, ask for one

## Process

### 1. Gather Context

**Reference file:** Read `docs/product-context.md` from the current repo for Confluence entry points and Jira config.

**Jira issue:** Fetch the epic/solution via Atlassian MCP (`getJiraIssue`). Extract:
- Title, description, acceptance criteria
- Linked issues (parent, children, related)
- Any linked Confluence pages or external URLs

**Confluence context:** 
- Fetch team home page descendants (page ID `5148770323`) to discover relevant child pages
- Fetch "Useful docs" aggregator (page ID `6212517970`) for external doc links
- Selectively fetch pages from Reqs/, Design/, Analysis docs/ folders that match the epic's theme
- Do NOT fetch everything — only what's relevant to this specific epic

**External docs (Google Docs, Whimsical, UX links):**
- List any that appear relevant based on title/description
- For Whimsical links: use the Whimsical MCP service if available to fetch board content directly
- For other unfetchable docs: ask the user "These external docs might be relevant — would you like to provide any excerpts?"
- Do not block on this — proceed with available context if user declines

**Codebase scan:**
- `internal/` — source of truth for what's currently implemented
- `docs/` — living documentation, treat as current
- `plans/` — point-in-time only; useful for understanding past intent and decisions, NOT authoritative on current state

### 2. Synthesise Analysis

Produce a structured analysis with these sections:

```
## Summary
[1-2 sentence summary of what the epic/solution is asking for]

## Context Gathered
- [Which Confluence pages were read]
- [Which code areas were inspected]
- [Any external docs noted but not fetched]

## Gap Analysis
- [What's unclear or ambiguous in the epic]
- [Missing requirements or acceptance criteria]
- [Contradictions with existing docs or implementation]

## Scope Assessment
- [What's already implemented in the codebase]
- [What's partially done]
- [What's entirely net-new work]

## Risks & Open Questions
- [Technical risks]
- [Dependency risks]
- [Questions that need PO/team clarification]
```

Keep each section terse. Bullet points, not paragraphs.

### 3. Propose Stories (if --propose mode)

After presenting the analysis, propose user stories:

- Use the `user-story` skill format (As a/I want/So that, numbered AC, optional notes)
- Group stories logically (e.g., by feature area or dependency order)
- Suggest a title for each story (under 70 characters, no ticket prefix)
- Indicate suggested priority/order
- Flag which stories depend on others

Present all proposed stories for user review. Do NOT create in Jira until explicitly approved.

### 4. Create in Jira (on approval)

When the user approves (all or a subset):

- Create each story via `createJiraIssue` MCP tool
- Set project: CBP
- Set team field (`customfield_12000`): `bb704fc2-5acd-4a64-99a6-af5684c0d17c`
- Link to parent epic
- Set acceptance criteria in ADF format (`customfield_12662`)
- Report back with links to created issues

## Rules

- NEVER create Jira issues without explicit user approval
- Fetch only relevant Confluence pages, not the entire tree
- Treat plans/ as historical context, not current state
- If the epic is too large or vague to analyse meaningfully, say so and suggest what clarification is needed from the PO
- If a Google Doc or Whimsical link appears critical but you can't fetch it, explicitly flag this rather than proceeding with incomplete context

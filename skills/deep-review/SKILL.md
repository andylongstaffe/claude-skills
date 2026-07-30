---
name: deep-review
allowed-tools: Bash(git *:*)
description: Multi-reviewer parallel code review across 5 lenses with full repo context, then synthesis. Can be invoked standalone or driven by review-pr --deep.
argument-hint: [jira-ticket-number]
disable-model-invocation: true
---

# Deep Review Workflow

Runs 5 specialist reviewers in parallel — each with a dedicated lens and appropriate model — then synthesises findings into a single prioritised report.

When invoked standalone, gathers the diff and repo path from the local working tree. When driven by `review-pr --deep`, those inputs are supplied by the caller (PR diff + worktree path).

## Reviewers and Models

| Lens | Model | Focus |
|------|-------|-------|
| Technical accuracy | `opus` | Logic correctness, edge cases, subtle bugs |
| Completeness | `sonnet` | Missing cases, error handling, coverage gaps |
| Clarity | `haiku` | Naming, readability, dead code, unnecessary complexity |
| Security | `opus` | OWASP top 10, injection, auth/authz, secrets, data exposure |
| Testing | `sonnet` | Test coverage, assertion quality, test isolation, missing cases |

## Workflow

1. Gather inputs (diff + repo path)
2. Run all 5 reviewers in parallel
3. Synthesise findings
4. Report to user
5. Optionally commit and push (standalone only)

---

## Instructions

### Step 1: Gather Inputs

**If invoked standalone** (no inputs supplied by a caller):
- Run `git diff HEAD` (and `git diff --cached` if anything is staged) to get the full diff
- Run `git rev-parse --show-toplevel` to get the repo root — this is the `repo-path`
- Run `git status` to confirm scope

**If driven by `review-pr --deep`** (caller supplies `diff` and `repo-path`):
- Skip this step — use the supplied values directly

### Step 2: Fan Out — 5 Parallel Reviews

Use the Workflow tool to run all five reviewers concurrently. Each reviewer uses the code-reviewer subagent with its designated model and lens-specific prompt.

Pass **both** the diff **and** the `repo-path` to every reviewer. The repo path allows each reviewer to read surrounding files, check for existing utilities, and verify pattern consistency beyond the diff.

**Technical accuracy reviewer (opus):**
- Logical correctness and control-flow bugs
- Off-by-one errors, nil/null dereferences, race conditions
- Edge cases and boundary conditions
- Incorrect assumptions about external APIs or data shapes
- Cross-check changed code against related files in `repo-path` for interface consistency

**Completeness reviewer (sonnet):**
- Missing error handling or fallback paths
- Unhandled input cases
- Incomplete implementations (TODO/FIXME left in)
- Missing validation at system boundaries
- Check `repo-path` for similar code paths that handle cases the diff does not

**Clarity reviewer (haiku):**
- Poor or misleading naming
- Unnecessary complexity or abstraction
- Dead code, redundant conditions
- Comments that describe *what* rather than *why*
- Check `repo-path` for naming conventions already established in the codebase

**Security reviewer (opus):**
- Injection vulnerabilities (SQL, command, template)
- Authentication and authorisation bypasses
- Hardcoded secrets or credentials
- Insecure data exposure (logging PII, overly broad error messages)
- OWASP Top 10 issues relevant to Go/gRPC services
- Check `repo-path` for existing security patterns (auth middleware, input sanitisation) and flag deviations

**Testing reviewer (sonnet):**
- Missing test cases for new code paths
- Assertions that test the wrong thing (e.g. `assert.Error` msg arg used as content check — it's a failure message, not a content check; use `assert.ErrorContains` for content)
- Tests that mock too aggressively and miss type mismatches
- Lack of handler→service integration tests for new handlers
- Test isolation issues (shared state, order-dependent tests)
- Check `repo-path` for existing test patterns and flag inconsistencies

### Step 3: Synthesise

After all five return, produce a single deduplicated report:

1. **Critical / High** — must fix before commit (all security findings are at least High)
2. **Medium** — should fix; flag if skipping
3. **Low / Suggestions** — optional improvements

Collapse duplicate findings (same issue spotted by multiple reviewers) into one entry, noting which lenses flagged it. Lead with the most actionable fix.

### Step 4: Report Findings

Present the synthesised report clearly. Include:
- Finding count per lens
- Any consensus findings (flagged by 2+ reviewers)
- Overall assessment: **PASS** / **PASS WITH NOTES** / **FAIL**

**If driven by `review-pr --deep`**: stop here — return findings and overall assessment to the caller. The caller (review-pr) owns the feedback loop and cleanup.

### Step 5: Ask User if They Want to Commit (standalone only)

Use AskUserQuestion:
- Question: "Would you like to proceed with committing and pushing these changes?"
- Options:
  - "Yes, commit and push" (only if no critical/high issues)
  - "No, I'll review the findings first"

**IF user says NO or IF critical/high issues exist:** stop here. Do not commit.

**IF user says YES and no critical/high issues:** proceed to Step 6.

### Step 6: Prepare for Commit (standalone, approved only)

- Run `git branch --show-current`
- **IF on main/master:** STOP — tell user to create a feature branch first.
- Check for JIRA ticket number in $ARGUMENTS; ask if not provided.

### Step 7: Commit and Push (standalone, approved only)

- Stage changes: `git add .`
- Suggest commit message; ask user to confirm or amend.
- Commit format:
  ```
  fix(cbp-XXXXX): concise reason for the change

  Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
  ```
- Push: `git push -u origin <branch-name>`
- Display PR URL.

## Important Notes

- **NEVER commit to main/master**
- Security findings are always treated as at least High severity
- Never commit if critical or high issues remain
- Always ask before committing (standalone only)

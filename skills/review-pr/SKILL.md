---
name: review-pr
description: Review a pull request from a GitHub URL. Use when the user provides a PR link and wants a code review.
argument-hint: <pr-url>
disable-model-invocation: true
---

# PR Review Workflow

Reviews a GitHub pull request and reports findings. Learns from your feedback over time.

## Workflow

1. Extract owner, repo, and PR number from the provided URL
2. Locate the repo locally (if available)
3. Read learned review preferences (if any)
4. Fetch the PR diff and details
5. Review using the code-reviewer subagent, guided by preferences and local context
6. Report findings to the user
7. Ask for feedback and update preferences

## Instructions

### Step 1: Fetch PR Details

Extract the PR info from `$ARGUMENTS` (expects a URL like `https://github.com/owner/repo/pull/123`).

Fetch the PR metadata and diff:
```bash
gh pr view <number> --repo <owner>/<repo> --json title,body,baseRefName,headRefName,files
gh pr diff <number> --repo <owner>/<repo>
```

If `gh` fails with TLS errors (corporate proxy), fall back to:
```bash
curl -sSf -k -H "Authorization: token $(gh auth token)" \
  "https://api.github.com/repos/<owner>/<repo>/pulls/<number>"
```

### Step 2: Locate Repo Locally

Try to find the repo on disk so the code-reviewer can check patterns, duplication, and context beyond the diff.

Search order:
1. Current working directory — check if `git remote -v` matches the PR repo
2. Sibling directories — `ls ../` for a directory matching the repo name, verify with `git remote -v`
3. Common dev paths — `~/dev/`, `~/dev/platform/`, `~/src/` (check for `<org>/<repo>` or just `<repo>`)

If found, note the path. If not found, proceed without local context — the review will be diff-only.

**If local repo found — set up worktree for the PR branch:**

The user may be working on a different branch. Never switch their branch. Instead, create a temporary git worktree for the PR's head branch:

```bash
# Fetch the PR branch
git -C <repo-path> fetch origin <pr-head-branch>

# Create a temporary worktree
git -C <repo-path> worktree add /tmp/review-pr-<number> FETCH_HEAD --detach
```

Use the worktree path (`/tmp/review-pr-<number>`) as the local repo path for the code-reviewer. This gives full codebase access on the correct branch without touching the user's working directory.

**After the review is complete (Step 6), clean up the worktree:**

```bash
git -C <repo-path> worktree remove /tmp/review-pr-<number> --force
```

Tell the user which mode is being used:
- "Found local repo at `<path>` — using worktree for PR branch, reviewing with full codebase context."
- "Repo not found locally — reviewing from diff only."

### Step 3: Load Review Preferences

Read `~/.claude/skills/review-pr/review-preferences.md` if it exists. These are learned preferences from prior reviews — pass them to the code-reviewer subagent as additional review guidance.

If the file doesn't exist, proceed without preferences.

### Step 4: Review Code

Use the code-reviewer subagent to review the diff. Focus on:
- Security issues
- Code quality problems
- Potential bugs
- Performance concerns
- Consistency with existing patterns
- Code duplication (if local repo available)

Provide the subagent with:
- PR title, description, base branch, and full diff
- All loaded review preferences as additional guidance
- If local repo was found: the repo path, so it can read surrounding files to check for pattern consistency, duplication, and broader context. Instruct it to check whether changed code duplicates existing utilities or diverges from established patterns.

### Step 5: Report Findings

Show the user a summary:
- PR title and branch info
- List any critical or high-priority issues
- List any medium/low priority suggestions
- Overall assessment

### Step 6: Collect Feedback

After presenting findings, ask:

> "Any feedback on this review? For example: findings you disagree with, things I missed, areas you want me to focus on more/less in future reviews. Say 'no' to skip."

**IF the user provides feedback:**
- Distil it into concise preference rules (one line each)
- Append to `~/.claude/skills/review-pr/review-preferences.md`
- Each entry should be actionable guidance, not a record of the conversation
- Confirm what was saved

**IF the user says no/skip:**
- End the review

## Review Preferences Format

`review-preferences.md` is a flat list of learned rules, one per line:

```markdown
- Don't flag missing error wrapping on test helper functions
- Emphasise nil pointer risks in DAO layer — we've been burned before
- SQL injection in raw queries is always critical, even in internal tools
- Prefer concrete suggestions over vague "consider refactoring" comments
```

**Guidelines for writing preference entries:**
- Lead with what to do or not do
- Include brief rationale if it's not obvious
- Keep each entry to one line
- Remove or update entries if the user contradicts a previous preference

## Important Notes

- This skill is read-only — it does not approve, comment on, or merge the PR
- If the user wants to leave comments, suggest they do so manually or ask explicitly
- If the URL is not a valid GitHub PR URL, ask the user to provide one

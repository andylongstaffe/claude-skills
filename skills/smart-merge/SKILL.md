---
name: smart-merge
description: Use when there are open dependency bump PRs from Renovate (security-labelled or not) that need reviewing, merging, or closing. Use when asked to triage, review, or action dependency or security PRs on any service.
---

# Security PR Triage

Triage all open Renovate dependency PRs: assess risk, merge low-risk ones, flag high-risk for human review, post Slack summary. The `security` label means Renovate found a known CVE — unlabelled PRs are routine bumps but still included.

## Steps

### 0. Identify repo

If the repo is not already known, detect it from the current working directory:

```bash
git remote get-url origin | sed 's/.*github.com[:/]\(.*\)\.git/\1/'
```

If this produces a valid `org/repo` string, use it for all subsequent `--repo` flags. If not (not in a git repo, or remote isn't GitHub), ask the user to supply the repo.

Also detect the language by checking for these files in the repo root (in order):
- `go.mod` → Go
- `package.json` → Node
- `pom.xml` → Java/Maven
- `requirements.txt` or `pyproject.toml` → Python
- None found → Unknown

### 1. Discover dependency PRs

```bash
gh pr list --repo <org/repo> --state open \
  --json number,title,author,labels,statusCheckRollup \
  --jq '[.[] | select(.labels[].name == "dependencies")]'
```

Note which PRs also carry the `security` label — that means Renovate identified a known CVE. Unlabelled dep bumps are still included but treated as lower urgency.

Discard any PR whose title contains "abandoned" or whose dep version is already present in the manifest. Check using the appropriate command for the detected language:

| Language | Check |
|----------|-------|
| Go | `grep '<module>' go.mod` |
| Node | `jq '.dependencies["<pkg>"] // .devDependencies["<pkg>"]' package.json` |
| Java | `grep '<artifactId>' pom.xml` |
| Python | `pip show <pkg> \| grep Version` |

### 2. For each PR, collect

```bash
gh pr view <N> --repo <org/repo> \
  --json title,body,files,statusCheckRollup,mergeable
```

Extract:
- **CVEs** and CVSS scores from the PR body (Renovate includes them)
- **Files changed** — should be only manifest/lockfiles for dep bumps (e.g. `go.mod`/`go.sum`, `package.json`/`package-lock.json`, `pom.xml`, `requirements.txt`)
- **CI status** — all checks must be green (build + Snyk minimum)
- **Semver delta** — patch/minor = low risk; major = flag for human

### 3. Check the dependency chain

Run the appropriate command for the detected language:

| Language | Chain command |
|----------|---------------|
| Go | `go mod why -m <module>` |
| Node | `npm why <pkg>` or `yarn why <pkg>` (check for `yarn.lock` to decide) |
| Java | `mvn dependency:tree -Dincludes=<groupId>:<artifactId>` |
| Python | `pip show <pkg>` (shows dependents — no full chain available) |
| Unknown | Skip — note language not supported yet |

Identifies which of your packages pulls in the dep and via what intermediary.

### 4. Apply risk criteria and present for approval

**Low risk (recommend auto-merge) when ALL of:**
- Diff is only manifest/lockfiles (no source code changes)
- All CI checks green
- Indirect/transitive dependency (not directly imported by your code)
- Patch or minor version bump
- CVE does not match service's attack surface (e.g. HTML parser CVE in a gRPC-only service)

**Flag for human review if ANY of:**
- Direct dependency (imported by your code)
- Major version bump
- CVSS ≥ 7.0
- Vulnerable code path is clearly reachable (e.g. net/http DoS in a service handling arbitrary HTTP input)
- Source code changes included alongside the manifest bump

**STOP here.** Present the full assessment to the human — one entry per PR with risk score and recommended action. Then ask:

> "Shall I auto-merge all low-risk PRs, or would you like to review them first?"

- If **auto-merge**: proceed immediately for low-risk PRs. High-risk PRs always require explicit human sign-off regardless.
- If **review first**: wait for explicit per-PR or blanket approval before acting on anything.

Do not merge, close, or approve any PR until the human has responded.

### 5. Act

**Low risk:** approve + merge
```bash
gh pr review <N> --repo <org/repo> --approve \
  --body "Approved by <name> via Claude agent after automated security triage. Low-risk indirect dep bump (manifest/lockfiles only), all CI green."
gh pr merge <N> --repo <org/repo> --merge
```

**Superseded:** close with comment
```bash
gh pr close <N> --repo <org/repo> \
  --comment "Closing as superseded — <module> <version> is already in main."
```

**High risk:** report for human review, do not merge.

### 6. Generate Slack summary

Use this format (list, not table — Slack doesn't render markdown tables):

```
*Dependency PR triage — <repo>* (<date>)

*#NNN — <module>* <PR URL>
• Label: 🔒 Security CVE / 📦 Routine bump
• CVE: <CVE ID> — <one-line description>  (omit if no CVE)
• Risk: <Low/Medium/High> — <one-line reason>
• Action: <Merged ✓ / Closed as superseded / Needs human review>

*Dependency chains:*
• `<module>` → `<intermediary>` → `<your package>`. Only reachable if <condition>.

*Regression probability:*
• `<module>` vX → vY: <Very low/Low/Medium>. <One sentence rationale>. Full CI + preprod deploy <green/failed>.

Approved by <name> via Claude agent.
```

## Notes

- Branch protection may require a human review even for bot PRs — attempt merge after approving; if blocked, report in Slack summary.
- Go: `go mod why` returns `(main module does not need package ...)` when the module is a transitive-only dep with no reachable package path — still indirect, note it as such.
- Check the current manifest before assessing any PR — the fix may already be in main.

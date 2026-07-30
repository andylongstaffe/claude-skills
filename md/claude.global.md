## Github

- Your primary method for interacting with Github should be the github CLI
- `gh` works correctly — `enableWeakerNetworkIsolation: true` is set in `~/.claude/settings.json`, allowing Go-based tools to verify TLS certificates via macOS trustd inside the sandbox.

## Development principles

- KISS (Keep It Simple, Stupid)
- YAGNI (You Aren't Gonna Need It)
- SOLID Principles
- DRY (Don't Repeat Yourself)

## Plans

- Please be as concise as possible and sacrifice grammar for the sake of concision.
- At the end of each plan, give a list of unresolved questions to answers. Make questions concise.
- Save plans as markdown file in a /plans directory for easy review
- Accuracy over assumptions. When in doubt about anything, always ask rather than guessing or making up assumptions. This applies to all work.

## Version control

- Always work on a branch — never commit directly to main in any repo. Create branches of the format cbp-12345-short-description where the first part is the JIRA ticket number. Ensure we are using the latest version of main.
- Commit comments should be of the format: "fix(cbp-12345): short description" where the reference is the JIRA number. Please ask for the JIRA number if unsure or not given. Description should be as concise as possible and given the reason behind the change and any interesting decisions rather than what has changed. Nouns should be one of fix,feat,test,chore as appropriate.
- **Always use the code-reviewer subagent to review code before committing.** Address any critical or high-priority issues found before proceeding with the commit.
- **Don't commit anything until it has been manually reviewed by the user first.**
- When code is ready for manual review, open GoLand by running `echo open-goland /path/to/directory` where the path is the repo root or worktree directory. A hook handles the launch.
- **Git commit/push requires `dangerouslyDisableSandbox: true`** — GPG signing needs access to `~/.gnupg` which the sandbox blocks.

## Worktrees

- Standardise on the native `EnterWorktree` tool for worktrees — it lands them in `.claude/worktrees/<branch>`, which is the expected, consistent location. Do not create ad-hoc `git worktree add` worktrees elsewhere (repo root, outside the project); consistency matters more than location.
- Advantages of the native tool: real session switch into the worktree, automatic keep/remove cleanup on exit, and base-ref handling via `worktree.baseRef` (`fresh` = origin/main, `head` = current HEAD — use `head` to stack on unmerged commits).
- Untracked files (e.g. a just-written design doc) do NOT travel to a new worktree — copy them over after creating it.

## Implementation

- When executing a plan (superpowers executing-plans / subagent-driven-development), always use the sub-agent-driven approach (option 1) without asking. State that it has been chosen, then proceed — don't pause for that decision.
- Please keep progress in plan uptodate automatically (ticking off each step as its done)
- Always minimise refactoring code alongside functional change to make it easier to see actual changes. Suggest spliting the work up into refactoring and functional changes.
- After each phase run unit tests and make sure they pass. Also run any linters.
- `go build`, `go test`, and `golangci-lint` require `dangerouslyDisableSandbox: true` — the Go build cache (`~/Library/Caches/go-build/`) is outside sandbox-allowed paths.

## Docker / Integration Tests

- Docker should be available for running integration tests (testcontainers). If Docker is not running or unavailable, notify the user rather than proceeding without integration tests.

## Testing

- **Never modify production code solely to accommodate tests** - use mocks, test doubles, or test-specific setup instead
- Production code should be optimized for production use cases, not test scenarios
- Only modify production code if the change provides genuine production value (better error handling, clearer APIs, etc.)
- When tests need special handling, ask: "Does this change improve production behavior?" If not, use a mock
- Example: Generate `mock.NewMockX()` and inject it rather than adding nil checks to production code

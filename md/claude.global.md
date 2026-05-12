## Github

- Your primary method for interacting with Github should be the github CLI
- `gh` fails behind the corporate proxy with TLS errors — use `curl -sSf -x http://localhost:57765 -k` with `gh auth token` instead. Do not attempt env var workarounds (`GIT_SSL_NO_VERIFY` etc.) — Go's TLS stack ignores them.

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

- Please create branches from main if needed of the format cbp-12345-short-description where the first part is the JIRA ticket number. Ensure we are using the latest version of main.
- Commit comments should be of the format: "fix(cbp-12345): short description" where the reference is the JIRA number. Please ask for the JIRA number if unsure or not given. Description should be as concise as possible and given the reason behind the change and any interesting decisions rather than what has changed. Nouns should be one of fix,feat,test,chore as appropriate.
- **Always use the code-reviewer subagent to review code before committing.** Address any critical or high-priority issues found before proceeding with the commit.
- **Don't commit anything until it has been manually reviewed by the user first.**
- When code is ready for manual review, open GoLand by running `echo open-goland /path/to/directory` where the path is the repo root or worktree directory. A hook handles the launch.
- **Git commit/push requires `dangerouslyDisableSandbox: true`** — GPG signing needs access to `~/.gnupg` which the sandbox blocks.

## Implementation

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

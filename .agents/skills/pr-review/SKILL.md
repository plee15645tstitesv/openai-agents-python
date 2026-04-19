# PR Review Skill

Automatically reviews pull requests for code quality, test coverage, and consistency with project standards.

## What it does

- Analyzes changed files in a pull request
- Checks for missing tests relative to new code
- Validates docstrings and type annotations
- Flags potential issues (e.g., broad exception handling, missing error handling)
- Posts a structured review comment summarizing findings

## Trigger

Runs on every opened or updated pull request via CI or agent invocation.

## Inputs

| Variable | Description |
|---|---|
| `PR_NUMBER` | The pull request number to review |
| `GITHUB_TOKEN` | Token with read/write access to the repo |
| `OPENAI_API_KEY` | API key for the review agent |
| `REPO` | Repository in `owner/name` format |

## Outputs

- A GitHub PR review comment with categorized findings
- Exit code `0` on success, non-zero on failure

## Usage

```bash
export PR_NUMBER=42
export GITHUB_TOKEN=ghp_...
export OPENAI_API_KEY=sk-...
export REPO=my-org/openai-agents-python
bash .agents/skills/pr-review/scripts/run.sh
```

## Review Categories

- **Critical**: Issues that must be fixed before merge
- **Warning**: Suggestions strongly recommended
- **Info**: Minor style or documentation notes

## Notes

- The skill skips generated files and vendored dependencies
- Reviews are idempotent: re-running updates the existing bot comment rather than posting a duplicate

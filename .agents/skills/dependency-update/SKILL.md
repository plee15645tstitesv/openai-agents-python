# Dependency Update Skill

This skill automates checking and updating project dependencies, ensuring the project stays current with the latest compatible versions.

## What it does

1. Scans `pyproject.toml` and any `requirements*.txt` files for outdated dependencies
2. Checks PyPI for latest versions
3. Evaluates compatibility and semver constraints
4. Creates a summary report of available updates
5. Optionally applies safe (patch/minor) updates automatically

## When to use

- Scheduled dependency maintenance
- Before a release to ensure no known vulnerabilities
- After a long development cycle to catch up on updates
- When a security advisory affects a dependency

## Inputs

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `UPDATE_MODE` | `check` (report only) or `apply` (apply safe updates) | No | `check` |
| `SEMVER_LEVEL` | Which updates to apply: `patch`, `minor`, or `major` | No | `minor` |
| `EXCLUDE_PACKAGES` | Comma-separated list of packages to skip | No | `` |
| `PYTHON_VERSION` | Python version to use for compatibility checks | No | `3.11` |

## Outputs

- `dependency-update-report.md` — Full report of current vs latest versions
- Updated `pyproject.toml` (if `UPDATE_MODE=apply`)
- Exit code `0` if no breaking changes, `1` if manual review needed

## Example usage

```yaml
- skill: dependency-update
  inputs:
    UPDATE_MODE: apply
    SEMVER_LEVEL: minor
    EXCLUDE_PACKAGES: "openai,pydantic"
```

## Notes

- Major version updates are never applied automatically; they are flagged in the report
- The skill respects version pins and constraints defined in `pyproject.toml`
- A backup of `pyproject.toml` is created before any modifications

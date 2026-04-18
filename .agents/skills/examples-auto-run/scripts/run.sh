#!/bin/bash
# examples-auto-run skill: discovers and runs all examples, reporting pass/fail
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
EXAMPLES_DIR="${ROOT_DIR}/examples"
REPORT_FILE="${ROOT_DIR}/.agents/skills/examples-auto-run/report.md"
TIMEOUT=${TIMEOUT:-60}
PYTHON=${PYTHON:-python}

passed=0
failed=0
skipped=0
failed_list=()

echo "# Examples Auto-Run Report" > "$REPORT_FILE"
echo "Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "| Example | Status | Notes |" >> "$REPORT_FILE"
echo "|---------|--------|-------|" >> "$REPORT_FILE"

if [ ! -d "$EXAMPLES_DIR" ]; then
  echo "ERROR: examples directory not found at $EXAMPLES_DIR" >&2
  exit 1
fi

# Find all example python files (top-level scripts or main.py in subdirs)
mapfile -t EXAMPLE_FILES < <(find "$EXAMPLES_DIR" -maxdepth 2 -name '*.py' | sort)

if [ ${#EXAMPLE_FILES[@]} -eq 0 ]; then
  echo "No example files found in $EXAMPLES_DIR" >&2
  exit 1
fi

for example in "${EXAMPLE_FILES[@]}"; do
  rel_path="${example#$ROOT_DIR/}"

  # Skip __init__ and utility files
  basename=$(basename "$example")
  if [[ "$basename" == __* ]] || [[ "$basename" == _* ]]; then
    skipped=$((skipped + 1))
    echo "| $rel_path | ⏭ skipped | utility/init file |" >> "$REPORT_FILE"
    continue
  fi

  # Check if the file requires interactive input or live API keys
  if grep -qE 'input\(|getpass\.' "$example" 2>/dev/null; then
    skipped=$((skipped + 1))
    echo "| $rel_path | ⏭ skipped | requires interactive input |" >> "$REPORT_FILE"
    continue
  fi

  echo "Running: $rel_path"
  set +e
  output=$(cd "$ROOT_DIR" && timeout "$TIMEOUT" "$PYTHON" "$example" 2>&1)
  exit_code=$?
  set -e

  if [ $exit_code -eq 124 ]; then
    failed=$((failed + 1))
    failed_list+=("$rel_path")
    echo "| $rel_path | ❌ failed | timed out after ${TIMEOUT}s |" >> "$REPORT_FILE"
  elif [ $exit_code -ne 0 ]; then
    # Distinguish missing API key errors as skipped
    if echo "$output" | grep -qiE 'api.?key|authentication|unauthorized|OPENAI_API_KEY'; then
      skipped=$((skipped + 1))
      echo "| $rel_path | ⏭ skipped | missing API credentials |" >> "$REPORT_FILE"
    else
      failed=$((failed + 1))
      failed_list+=("$rel_path")
      first_error=$(echo "$output" | tail -5 | tr '\n' ' ' | cut -c1-120)
      echo "| $rel_path | ❌ failed | $first_error |" >> "$REPORT_FILE"
    fi
  else
    passed=$((passed + 1))
    echo "| $rel_path | ✅ passed | |" >> "$REPORT_FILE"
  fi
done

echo "" >> "$REPORT_FILE"
echo "## Summary" >> "$REPORT_FILE"
echo "- ✅ Passed: $passed" >> "$REPORT_FILE"
echo "- ❌ Failed: $failed" >> "$REPORT_FILE"
echo "- ⏭ Skipped: $skipped" >> "$REPORT_FILE"

echo ""
echo "=== Examples Auto-Run Summary ==="
echo "Passed:  $passed"
echo "Failed:  $failed"
echo "Skipped: $skipped"
echo "Report:  $REPORT_FILE"

if [ ${#failed_list[@]} -gt 0 ]; then
  echo ""
  echo "Failed examples:"
  for f in "${failed_list[@]}"; do
    echo "  - $f"
  done
  exit 1
fi

exit 0

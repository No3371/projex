#!/usr/bin/env bash
# Runs every bash suite. Each suite builds throwaway repos under $TMPDIR and cleans up after itself;
# nothing touches the repo you run it from.
# Usage: tests/run-all.sh
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

TOTAL_PASS=0
TOTAL_FAIL=0
STATUS=0
CLOSE_PRECHECK_RUNS=0

for suite in resolve-conflicts.test.sh resume.test.sh worktree.test.sh dirty-base.test.sh close-precheck.test.sh; do
  echo "=== $suite"
  [ "$suite" = close-precheck.test.sh ] && CLOSE_PRECHECK_RUNS=$((CLOSE_PRECHECK_RUNS + 1))
  # git writes CRLF/LF advisories to stderr on Windows checkouts; they are noise here
  out=$(bash "$suite" 2>/dev/null)
  suite_status=$?
  echo "$out" | grep -E '^FAIL|^PASS=|no summary' || true
  summary_count=$(printf '%s\n' "$out" | grep -c '^PASS=[0-9][0-9]* FAIL=[0-9][0-9]*$' || true)
  if [ "$suite_status" -ne 0 ] || [ "$summary_count" -ne 1 ]; then
    echo "  (suite failed or did not emit exactly one PASS=N FAIL=M summary)"
    STATUS=1
    continue
  fi
  line=$(printf '%s\n' "$out" | grep '^PASS=' | tail -n 1)
  p=$(printf '%s\n' "$line" | sed -n 's/^PASS=\([0-9]*\).*/\1/p')
  f=$(printf '%s\n' "$line" | sed -n 's/.*FAIL=\([0-9]*\)$/\1/p')
  TOTAL_PASS=$((TOTAL_PASS + p))
  TOTAL_FAIL=$((TOTAL_FAIL + f))
  [ "$f" -eq 0 ] || STATUS=1
done

if [ "$CLOSE_PRECHECK_RUNS" -ne 1 ]; then
  echo "  (close-precheck.test.sh must execute exactly once; got $CLOSE_PRECHECK_RUNS)"
  STATUS=1
fi

echo "=== total: PASS=$TOTAL_PASS FAIL=$TOTAL_FAIL"
exit $STATUS

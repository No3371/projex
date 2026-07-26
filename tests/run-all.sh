#!/usr/bin/env bash
# Runs every bash suite. Each suite builds throwaway repos under $TMPDIR and cleans up after itself;
# nothing touches the repo you run it from.
# Usage: tests/run-all.sh
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

TOTAL_PASS=0
TOTAL_FAIL=0
STATUS=0

for suite in resolve-conflicts.test.sh resume.test.sh worktree.test.sh dirty-base.test.sh; do
  echo "=== $suite"
  # git writes CRLF/LF advisories to stderr on Windows checkouts; they are noise here
  out=$(bash "$suite" 2>/dev/null)
  echo "$out" | grep -E '^FAIL|^PASS=' || true
  line=$(echo "$out" | grep '^PASS=' | tail -n 1)
  p=$(echo "$line" | sed -n 's/^PASS=\([0-9]*\).*/\1/p')
  f=$(echo "$line" | sed -n 's/.*FAIL=\([0-9]*\)$/\1/p')
  TOTAL_PASS=$((TOTAL_PASS + ${p:-0}))
  TOTAL_FAIL=$((TOTAL_FAIL + ${f:-0}))
  [ "${f:-1}" -eq 0 ] || STATUS=1
done

echo "=== total: PASS=$TOTAL_PASS FAIL=$TOTAL_FAIL"
exit $STATUS

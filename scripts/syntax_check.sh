#!/usr/bin/env bash
# Syntax check all bash scripts: bash -n + shellcheck
set -uo pipefail
fail=0
echo "===== BASH SYNTAX CHECK ====="
for f in scripts/*.sh; do
  if bash -n "$f"; then echo "[OK]   bash -n  $f"; else echo "[FAIL] bash -n  $f"; fail=1; fi
  if command -v shellcheck >/dev/null 2>&1; then
    if shellcheck "$f"; then echo "[OK]   shellcheck $f"; else echo "[FAIL] shellcheck $f"; fail=1; fi
  else
    echo "[WARN] shellcheck not installed"; fail=1
  fi
done
[ "$fail" -eq 0 ] && echo "SYNTAX: PASS" || echo "SYNTAX: FAIL"
exit "$fail"

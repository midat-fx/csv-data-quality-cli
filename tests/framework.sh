#!/usr/bin/env bash
# framework.sh — a tiny, dependency-free golden-test harness.
#
# Reusable on its own: source it, then call assert_golden / assert_file /
# assert_exit, and finish with test_summary. Every golden assertion runs the
# command twice and fails if the two runs differ, so non-determinism is caught
# even when it happens to match the committed golden. Set UPDATE=1 to (re)write
# goldens. See docs/design.md.

: "${GOLDEN_DIR:=tests/golden}"
: "${UPDATE:=0}"
_pass=0
_fail=0

_ok() {
  _pass=$((_pass + 1))
  printf '  ok   %s\n' "$1"
}
_bad() {
  _fail=$((_fail + 1))
  printf '  FAIL %s: %s\n' "$1" "$2"
}

# assert_golden NAME -- CMD...
# Compares CMD's stdout to $GOLDEN_DIR/NAME (byte-exact) and checks determinism.
assert_golden() {
  local name="$1"
  shift
  [ "${1:-}" = "--" ] && shift
  local t1 t2 g
  t1="$(mktemp)"
  t2="$(mktemp)"
  g="$GOLDEN_DIR/$name"
  "$@" >"$t1" 2>/dev/null || true
  "$@" >"$t2" 2>/dev/null || true
  if ! cmp -s "$t1" "$t2"; then
    _bad "$name" "non-deterministic stdout"
    rm -f "$t1" "$t2"
    return
  fi
  if [ "$UPDATE" = "1" ]; then
    cp "$t1" "$g"
    _ok "$name (updated)"
    rm -f "$t1" "$t2"
    return
  fi
  if [ ! -f "$g" ]; then
    _bad "$name" "missing golden $g (run: UPDATE=1 $0)"
    rm -f "$t1" "$t2"
    return
  fi
  if cmp -s "$t1" "$g"; then _ok "$name"; else
    _bad "$name" "golden mismatch"
    diff -u "$g" "$t1" | head -25
  fi
  rm -f "$t1" "$t2"
}

# assert_file NAME GOLDEN ACTUAL — compare an already-produced file to a golden.
assert_file() {
  local name="$1" g="$GOLDEN_DIR/$2" actual="$3"
  if [ "$UPDATE" = "1" ]; then
    cp "$actual" "$g"
    _ok "$name (updated)"
    return
  fi
  if [ ! -f "$g" ]; then
    _bad "$name" "missing golden $g"
    return
  fi
  if cmp -s "$actual" "$g"; then _ok "$name"; else
    _bad "$name" "golden mismatch"
    diff -u "$g" "$actual" | head -25
  fi
}

# assert_exit NAME EXPECTED -- CMD... — assert the command's exit status.
assert_exit() {
  local name="$1" want="$2"
  shift 2
  [ "${1:-}" = "--" ] && shift
  local got=0
  "$@" >/dev/null 2>&1 || got=$?
  if [ "$got" = "$want" ]; then _ok "$name (exit $got)"; else _bad "$name" "exit $got, wanted $want"; fi
}

test_summary() {
  printf '\n%d passed, %d failed\n' "$_pass" "$_fail"
  [ "$_fail" -eq 0 ]
}

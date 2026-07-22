#!/usr/bin/env bash
# run_tests.sh — offline golden test suite for csvq. No network, no installs.
# Usage: tests/run_tests.sh          (run)
#        UPDATE=1 tests/run_tests.sh  (regenerate goldens)
#        CSVQ_AWK=gawk tests/run_tests.sh  (pick an awk implementation)

set -u
cd "$(cd "$(dirname "$0")/.." && pwd)" || exit 1 # repo root
export LC_ALL=C

. tests/framework.sh

CSVQ="./csvq.sh"
FX=tests/fixtures
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

printf 'csvq test suite (awk: %s)\n' "${CSVQ_AWK:-awk}"

# ---- audit: three reports over a fixed, ordered file set --------------------
"$CSVQ" audit "$FX/clean.csv" "$FX/crlf.csv" "$FX/dupes.csv" "$FX/ragged.csv" \
  "$FX/empty.csv" "$FX/quoted.csv" -o "$work/a1" 2>/dev/null
assert_file audit_analysis audit_analysis.txt "$work/a1/analysis_report.txt"
assert_file audit_summary audit_summary.txt "$work/a1/data_summary.txt"
assert_file audit_duplicates audit_duplicates.txt "$work/a1/duplicates_found.txt"

# audit determinism: a second run must be byte-identical
"$CSVQ" audit "$FX/clean.csv" "$FX/crlf.csv" "$FX/dupes.csv" "$FX/ragged.csv" \
  "$FX/empty.csv" "$FX/quoted.csv" -o "$work/a2" 2>/dev/null
for r in analysis_report data_summary duplicates_found; do
  if cmp -s "$work/a1/$r.txt" "$work/a2/$r.txt"; then _ok "audit_determinism_$r"; else _bad "audit_determinism_$r" "runs differ"; fi
done

# ---- stats ------------------------------------------------------------------
assert_golden stats_basic -- "$CSVQ" stats "$FX/stats.csv"
assert_golden stats_semicolon -- "$CSVQ" stats "$FX/semicolon.csv"

# ---- validate ---------------------------------------------------------------
assert_golden validate_fail -- "$CSVQ" validate "$FX/people.csv" --schema "$FX/people.schema"
assert_golden validate_ok -- "$CSVQ" validate "$FX/people_ok.csv" --schema "$FX/people.schema"
assert_exit validate_exit_fail 1 -- "$CSVQ" validate "$FX/people.csv" --schema "$FX/people.schema"
assert_exit validate_exit_ok 0 -- "$CSVQ" validate "$FX/people_ok.csv" --schema "$FX/people.schema"

# ---- diff -------------------------------------------------------------------
assert_golden diff_basic -- "$CSVQ" diff "$FX/old.csv" "$FX/new.csv" --key id

# ---- dedupe -----------------------------------------------------------------
assert_golden dedupe_basic -- "$CSVQ" dedupe "$FX/dupes.csv"
assert_golden dedupe_by_key -- "$CSVQ" dedupe "$FX/dupes.csv" --key id

# ---- normalize (byte-exact CRLF -> LF) --------------------------------------
assert_golden normalize_crlf -- "$CSVQ" normalize "$FX/crlf.csv"

# ---- meta -------------------------------------------------------------------
assert_golden help_text -- "$CSVQ" help
assert_exit version_ok 0 -- "$CSVQ" version
assert_exit audit_strict_clean 0 -- "$CSVQ" audit "$FX/clean.csv" -o "$work/s1" --strict
assert_exit audit_strict_dupes 1 -- "$CSVQ" audit "$FX/dupes.csv" -o "$work/s2" --strict
assert_exit bad_command 2 -- "$CSVQ" frobnicate
assert_exit missing_file 2 -- "$CSVQ" stats "$FX/does_not_exist.csv"

test_summary

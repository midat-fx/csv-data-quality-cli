# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-02-15

First stable release. `csvq` grew from a two-CSV assessment script into a small
deterministic data-quality toolkit.

### Added
- `audit` — writes `analysis_report.txt`, `data_summary.txt`,
  `duplicates_found.txt`; `--strict` turns it into a CI gate.
- `stats` — per-column type inference, null rate, cardinality, min/max/mean,
  and top values (omitted for high-cardinality columns).
- `validate` — a small schema DSL (types, `required`, `unique`, `min`/`max`,
  `regex`); exits non-zero on any violation.
- `diff` — keyed row diff (added / changed / removed) between two CSVs.
- `dedupe` — drop duplicate rows, whole-row or by `--key`.
- `normalize` — CRLF→LF, trailing-whitespace strip, final-newline guarantee.
- RFC 4180 quoting: quoted fields may contain the delimiter, escaped quotes,
  and embedded newlines.
- Automatic delimiter detection (comma / semicolon / tab / pipe).
- `tests/framework.sh` — a reusable, dependency-free golden-test harness that
  double-runs every command to catch non-determinism.
- CI matrix across GNU awk, mawk, and BSD awk; shellcheck + shfmt linting.

### Notes
- Output is deterministic: `LC_ALL=C`, no timestamps or paths-of-the-day.

## Roadmap

Tracked as GitHub issues:
- `sample` — deterministic reservoir sampling with a seeded PRNG.
- `check` — glob-scoped gate config (`.csvq.yml`).
- `audit --json` and an HTML report.
- Benchmarks job comparing against xsv / miller / csvkit.

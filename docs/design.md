# Design

## Layout

```
csvq.sh              Dispatcher: argument parsing, file expansion, exit codes.
lib/csvlib.awk       Shared functions: RFC 4180 parser, delimiter detection,
                     quote counting, type inference. Loaded first via -f.
lib/audit.awk        Per-file fact stream for `audit`.
lib/report_build.awk Assembles the three audit reports from the fact stream.
lib/stats.awk        Column statistics.
lib/validate.awk     Schema DSL loading + validation.
lib/diff.awk         Keyed two-file diff.
lib/dedupe.awk       Duplicate removal.
tests/               Golden harness, fixtures, golden outputs.
```

Each command is `awk -f lib/csvlib.awk -f lib/<cmd>.awk ...`. Loading two `-f`
files lets every command share one implementation of the parser while keeping
per-command logic isolated — no copy-paste of the CSV state machine.

## Parsing model

CSV is parsed character-by-character to stay identical across awk
implementations (no gawk `--csv`, no `FPAT`). Physical lines are accumulated
into a logical record until the running double-quote count is even, which is how
a quoted field containing a newline is reassembled into one record. `csv_parse`
then walks the record honouring `""` escapes and quoted delimiters.

This trades throughput for portability and correctness; see
[benchmarks.md](benchmarks.md). For the data-quality gate use case — tens of
thousands to a few million rows in CI — it is comfortably fast enough, and it
behaves the same on a laptop, a Debian runner (mawk), and Alpine (busybox awk).

## Audit fact stream

`audit.awk` emits a tab-separated stream per file (`@FILE`, `@ROWS`, `@COLS`,
`@DELIM`, `@CRLF`, `@RAGGED`, `@BYTES`, `@EMPTY`, `@DUPGROUPS`, `@DUPROWS`,
`#DUP`, `@EOB`). `report_build.awk` consumes it and writes the three reports.
The split keeps per-file analysis and cross-file aggregation independent and
makes the audit output easy to test and to re-render into other formats later.

## The test harness

`tests/framework.sh` is deliberately standalone so it can be vendored into an
unrelated project: copy the file, set `GOLDEN_DIR`, and call `assert_golden`,
`assert_file`, and `assert_exit`. Its defining feature is that every golden
assertion runs the command twice and fails on any difference, so
non-determinism is caught at the source rather than by a flaky diff months
later.

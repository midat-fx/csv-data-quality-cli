# Benchmarks

Numbers are honest and reproducible, not flattering. csvq is a pure awk program;
its character-by-character RFC 4180 parser is the throughput ceiling. Compiled,
SIMD-friendly tools (xsv, miller, csvkit) are an order of magnitude faster — csvq
trades that for zero dependencies, byte-level determinism, and running unchanged
on gawk, mawk, BSD awk and busybox awk.

## Setup

Dataset generated with `bench/gen.awk` (deterministic, seed 42):

```
awk -v rows=1000000 -v seed=42 -f bench/gen.awk > big.csv
# 1,000,000 data rows, 5 columns, ~37 MB
```

Measured on an Apple silicon laptop (macOS), wall-clock `time`, warm cache.

| Command          | awk  | Time   | Throughput      |
|------------------|------|--------|-----------------|
| `audit big.csv`  | gawk | ~8.6 s | ~116k rows/s    |
| `audit big.csv`  | mawk | ~11.4 s| ~88k rows/s     |
| `stats big.csv`  | mawk | ~18 s  | ~56k rows/s     |
| `gen 1M rows`    | mawk | ~0.6 s | —               |

Your hardware and awk build will differ; regenerate with the commands above.

## Reproduce

```
awk -v rows=1000000 -f bench/gen.awk > big.csv
time ./csvq.sh audit big.csv -o out
CSVQ_AWK=gawk time ./csvq.sh audit big.csv -o out
```

## Notes

- **Determinism holds at scale.** Auditing the 1M-row file twice produces
  byte-identical reports, and gawk/mawk/BSD awk agree.
- `stats` costs more than `audit` because it infers a type and tracks
  cardinality per cell. Top-value computation is bounded, so a
  million-distinct-value column does not blow up (it reports "high cardinality"
  instead of ranking a million values).
- When you need millions of rows per second, reach for a compiled tool. When you
  need a report that is identical everywhere and installs nowhere, that is csvq.

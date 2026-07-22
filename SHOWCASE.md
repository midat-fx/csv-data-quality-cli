# Showcase

Real output from the committed fixtures and a generated benchmark file. Every
figure below is reproducible with the commands shown.

## Audit as a CI gate

```
$ csvq audit examples/cities.csv --strict; echo "exit=$?"
csvq audit: wrote 3 report(s) to out/
csvq audit: --strict gate failed (1 file(s) with dupes, 0 with ragged rows)
exit=1
```

`data_summary.txt` for a six-file audit (fixtures):

```
files:              6
total data rows:    18
total bytes:        275
columns min/max:    0 / 3
files with crlf:    1
files with dupes:   1
files with ragged:  1
files empty:        1
total duplicate rows: 3
```

## Schema validation catches four issue classes at once

```
$ csvq validate examples/people.csv --schema examples/people.schema
  row 2: column 'email' value 'bad-email' fails regex ^[^@]+@[^@]+$
  row 2: column 'age' value 17 < min 18
  row 3: column 'age' is required but empty
  row 4: column 'id' value '1' is not unique
FAIL: 4 violation(s)     # exit 1
```

## Scale and determinism

- 1,000,000 rows / ~37 MB audited in ~8.6 s (gawk), ~11.4 s (mawk).
- The same file audited twice is **byte-identical**, and gawk / mawk / BSD awk
  produce the same reports against the same golden files.
- `stats` on a 1M-distinct-value column reports "high cardinality" instead of
  ranking a million values — bounded work, no quadratic blow-up.

See [docs/benchmarks.md](docs/benchmarks.md) to reproduce.

## Verified surface

22 golden + exit-code checks, run in CI under three awk implementations, plus
shellcheck, shfmt, and an in-container build.

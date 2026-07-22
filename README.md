# csvq — deterministic CSV data-quality toolkit

[![ci](https://github.com/midat-fx/csv-data-quality-cli/actions/workflows/ci.yml/badge.svg)](https://github.com/midat-fx/csv-data-quality-cli/actions/workflows/ci.yml)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![deps: none](https://img.shields.io/badge/runtime%20deps-none-brightgreen.svg)](#requirements)
[![awk: gawk · mawk · bsd · busybox](https://img.shields.io/badge/awk-gawk%20%C2%B7%20mawk%20%C2%B7%20bsd%20%C2%B7%20busybox-informational.svg)](docs/benchmarks.md)

Audit and clean CSV files from the shell, with **zero runtime dependencies** and
**byte-deterministic output** — so a data-quality report can be a CI gate that
never changes for a reason unrelated to your data.

Pure Bash + POSIX awk. Runs unchanged on GNU awk, mawk, BSD/macOS awk, and
busybox awk. Nothing to `pip install`, no binary to vendor.

```
$ csvq audit data/*.csv --strict
csvq audit: wrote 3 report(s) to out/
csvq audit: --strict gate failed (1 file(s) with dupes, 0 with ragged rows)   # exit 1
```

## Why

Data-quality checks belong in CI, but the usual options are a heavy Python stack
or a compiled binary you have to distribute. csvq is one shell script and a
handful of awk files you can drop into any repo or container. Its output carries
no timestamps, hostnames, or paths-of-the-day, so `git diff` on a committed
report shows *data* changes, never noise — and the same input is guaranteed to
produce the same bytes on every machine and every awk. See
[docs/determinism.md](docs/determinism.md).

## Install

```bash
git clone https://github.com/midat-fx/csv-data-quality-cli
cd csv-data-quality-cli
ln -s "$PWD/csvq.sh" /usr/local/bin/csvq   # optional, or just call ./csvq.sh
```

Or run it in a container:

```bash
docker build -t csvq .
docker run --rm -v "$PWD:/data" -w /data csvq audit input.csv
```

### Requirements

Bash and any POSIX awk. That's it. `gawk`, `mawk`, `busybox awk`, and the awk
shipped with macOS all work and are covered by CI.

## Commands

| Command      | What it does                                                            |
|--------------|-------------------------------------------------------------------------|
| `audit`      | Writes `analysis_report.txt`, `data_summary.txt`, `duplicates_found.txt`; `--strict` is a CI gate. |
| `stats`      | Per-column type, null rate, cardinality, min/max/mean, top values.      |
| `validate`   | Check a file against a [schema DSL](docs/schema-dsl.md); exits 1 on any violation. |
| `diff`       | Keyed row diff between two CSVs (added / changed / removed).             |
| `dedupe`     | Drop duplicate rows — whole row, or by `--key` — keeping the first.      |
| `normalize`  | CRLF→LF, strip trailing whitespace, ensure a final newline.             |

Delimiters (comma / semicolon / tab / pipe) are auto-detected; override with
`-d`. Quoted fields with embedded commas, escaped `""`, and embedded newlines
are parsed per RFC 4180.

## Examples

**Audit** a file and gate CI on it:

```console
$ csvq audit examples/cities.csv
csvq audit: wrote 3 report(s) to out/
$ cat out/duplicates_found.txt
...
File: examples/cities.csv
  duplicate groups: 1
  duplicate rows:   1
  top duplicated rows (count, row):
         2  2,Astana,1350000
```

**Validate** against a schema (types, required, unique, ranges, regex):

```console
$ csvq validate examples/people.csv --schema examples/people.schema
  row 2: column 'email' value 'bad-email' fails regex ^[^@]+@[^@]+$
  row 2: column 'age' value 17 < min 18
  row 3: column 'age' is required but empty
  row 4: column 'id' value '1' is not unique
FAIL: 4 violation(s)
$ echo $?
1
```

**Diff** two snapshots by key:

```console
$ csvq diff examples/sales_jan.csv examples/sales_feb.csv --key id
~ changed: 2 | amount=20->25
- removed: 3 | 3,Carol,30
+ added:   4 | 4,Dave,40

Summary: 1 added, 1 changed, 1 removed
```

**Column stats**, with bounded top-values on high-cardinality data:

```console
$ csvq stats examples/cities.csv
Column 2: city
  type:      string
  non-null:  4
  nulls:     0 (0.0%)
  distinct:  3
  top values: Astana (2), Almaty (1), Shymkent (1)
```

## Use it as a CI gate

```yaml
# .github/workflows/data.yml
- run: ./csvq.sh audit data/*.csv --strict          # fail on dupes/ragged rows
- run: ./csvq.sh validate data/users.csv --schema schema/users.csvq
```

## Design & determinism

- [docs/design.md](docs/design.md) — architecture, the shared awk library, the
  RFC 4180 parser, the audit fact stream, and the vendorable test harness.
- [docs/determinism.md](docs/determinism.md) — what "deterministic" means here
  and how it is enforced and tested.
- [docs/schema-dsl.md](docs/schema-dsl.md) — the validation schema language.
- [docs/benchmarks.md](docs/benchmarks.md) — honest throughput numbers.

## Performance

~90k–120k rows/second on a laptop (a 1M-row, 37 MB file audits in ~9–11 s),
identical output run-to-run and across awk implementations. Compiled tools like
xsv and miller are far faster; csvq's bet is zero dependencies, determinism, and
portability instead. Details and reproduction in
[docs/benchmarks.md](docs/benchmarks.md).

## Testing

```bash
tests/run_tests.sh                 # golden + exit-code suite (offline)
CSVQ_AWK=gawk tests/run_tests.sh   # pick an awk implementation
UPDATE=1 tests/run_tests.sh        # regenerate goldens after an intended change
```

CI runs the suite under GNU awk, mawk, BSD awk, and busybox awk against the same
goldens, plus shellcheck, shfmt, and an in-container build.

## Limitations

- The `validate` regex tokens cannot contain spaces.
- `diff` is line-oriented (one record per line); quoted delimiters within a line
  are handled, embedded newlines in the diffed files are not.
- See the roadmap in [CHANGELOG.md](CHANGELOG.md) for `sample`, `check`,
  `--json`, and HTML output.

## License

MIT © Midat Faizov. This is a public, clean-room implementation built to
demonstrate deterministic CLI tooling and data-quality checks.

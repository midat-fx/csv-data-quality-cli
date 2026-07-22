# Determinism

csvq treats byte-for-byte reproducibility as a correctness property, not a
nice-to-have. The same input must produce the same output on every run and on
every awk implementation, so that a report committed to a repository or checked
in CI never changes for a reason unrelated to the data.

## How it is enforced

- **`LC_ALL=C` everywhere.** Sorting and character classes are locale-stable, so
  `Å` and `a` never swap order between a developer's laptop and a CI runner.
- **No environmental noise in output.** Reports contain no timestamps, no
  hostnames, no run IDs, and no absolute paths that change per machine. The only
  paths printed are the ones you passed on the command line.
- **Explicit ordering.** Anywhere order matters — duplicate rankings, diff
  output, top values — csvq sorts by an explicit key with a deterministic
  tie-break (count desc, then value/row ascending). It never relies on awk's
  unspecified `for (k in array)` iteration order for output.
- **Custom, portable arithmetic.** Where a seeded random choice is needed, csvq
  uses its own linear-congruential generator (see `bench/gen.awk`) rather than
  `srand()`/`rand()`, which differ between awk implementations.

## How it is tested

`tests/framework.sh` runs every command **twice** and fails if the two runs
differ, even when both happen to match the committed golden. The audit path is
additionally run into two separate directories and compared. The CI matrix runs
the whole suite under GNU awk, mawk, and BSD awk against the *same* golden
files — proving the output is identical across implementations, not merely
self-consistent.

# Contributing

Thanks for taking a look. csvq is deliberately small and dependency-free.

## Dev setup

Nothing to install beyond a POSIX awk and Bash. To run the test suite:

    tests/run_tests.sh

Pick a specific awk implementation:

    CSVQ_AWK=gawk tests/run_tests.sh
    CSVQ_AWK=mawk tests/run_tests.sh

Regenerate golden files after an intentional output change:

    UPDATE=1 tests/run_tests.sh

## Rules of the house

- **Zero runtime dependencies.** Bash + POSIX awk + coreutils only. No Python,
  no perl, no gawk-only extensions (`gensub`, `asort`, `--csv`).
- **Determinism is a feature.** Any new output must be byte-identical run to run
  and across awk implementations: sort explicitly, never print timestamps,
  hostnames, or absolute paths of the day. The harness double-runs every command
  and fails on any difference.
- **Every command ships a golden test.** Add fixtures under `tests/fixtures/`
  and assertions in `tests/run_tests.sh`.
- Keep it lint-clean: `shellcheck` and `shfmt -i 2 -ci` must pass.

## Style

- Shell: `shfmt -i 2 -ci`.
- awk: two-space indent, function-local variables declared as trailing params.

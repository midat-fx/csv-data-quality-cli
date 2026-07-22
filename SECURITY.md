# Security Policy

Report any security issue privately to faizov.midat@gmail.com rather than opening
a public issue.

## Threat model

csvq is a local command-line tool. It makes **no network calls** and performs
**no code execution**: there is no `eval`, and every awk program is either a
static file under `lib/` or a fixed single-quoted string — your CSV data is only
ever passed to awk as *data* (`-v` values and quoted file arguments), never as a
program. All expansions are quoted (verified by shellcheck in CI), so a filename
or field value cannot inject shell commands.

Output paths (`-o`) and input files are whatever you pass on the command line;
csvq does not fetch or resolve anything on your behalf. A crafted CSV can at
worst produce odd report contents, not code execution.

# Testing

Tests are implemented in the `tests` child Alire crate with AUnit. Test tooling
is Ada code and is invoked through `awk_workflows`.

The primary suite is `awk_tests_main`. It exercises:

- option parsing, option failure diagnostics, original argument indexes, and
  `--` handling;
- program source resolution, including empty direct programs, multiple `-f`
  files, empty files, final-newline separation, and `-f` operand handling;
- operand classification for files, `-`, valid runtime assignments, and paths
  containing `=`;
- `awklib` execution integration for fields, `BEGIN`, regular-expression
  patterns, arithmetic, built-ins, `ENVIRON`, `ARGV`, `ARGC`, `getline < file`,
  standard output, and captured redirections;
- controlled host I/O failures for stdin, stdout, stderr, program files, input
  files, redirection open failures, and redirection write failures;
- localized diagnostics, unsupported-locale fallback, catalog syntax policy,
  placeholder compatibility, and diagnostic escaping;
- process-level execution of the installed `awk` binary for help, version,
  direct programs, `-f`, `-F`, `-v`, parse failures, multiple input files,
  dash-leading filenames after `--`, runtime assignment `ARGV`, and
  redirection.

The in-memory `Awk_CLI.Invocation_Context` lets tests provide arguments,
standard input, virtual files, environment entries, injected stream failures,
and captured writes without spawning the real executable. It also exposes the
last structured diagnostic identifier, category, and severity for tests that
should not depend only on rendered text.

The workflow command `./bin/awk_workflows verify` builds root and tests in
development mode, runs AUnit, validates required docs, validates English and
Danish catalogs, checks catalog placeholders and default locale policy, checks
adapter isolation, rejects handwritten ANSI sequences in presentation code,
rejects system-AWK fallback references, and rejects shell/script workflow files.

The release workflow runs the mandatory test and policy gates with release
builds, requires a clean git working tree, and packages the executable, message
catalogs, license, and documentation with byte counts and FNV-1a-64 checksums.

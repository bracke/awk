# Testing

Tests are implemented in the `tests` child Alire crate with AUnit. Test tooling
is Ada code and is invoked through `awk_workflows`.

The primary suite is `awk_tests_main`. It exercises:

Subsystem-focused AUnit packages live alongside the aggregate suite. The
`awk_tests-support` package owns shared test helpers for string search, file
reading, and fixture file writing. The
`awk_tests-cli_options` package owns option-parser tests, and
`awk_tests-program_sources` owns program-source resolution tests. The
`awk_tests-operands` package owns operand classification tests, and
`awk_tests-diagnostics` owns structured diagnostic rendering and sanitizing
tests. The `awk_tests-localization` package owns catalog validation,
locale-fallback, localized CLI text, and AWK-output locale-separation tests.
The `awk_tests-redirections` package owns in-memory output-redirection success,
append, ordering, and failure tests. The `awk_tests-execution` package owns
direct execution-adapter and live callback tests. The `awk_tests-process`
package owns real-executable process-boundary tests. The `awk_tests-inputs`
package owns in-memory standard-input, named-input, file-failure, and input
ordering tests. The `awk_tests-environment` package owns `ENVIRON`,
environment normalization, and environment-confidentiality tests. The
`awk_tests-terminal_styles` package owns destination-aware terminal styling
tests. The `awk_tests-compatibility` package owns compatibility-registry and
conformance-manifest tests. The `awk_tests-context` package owns broader
in-memory invocation-context integration tests.
`awk_tests-suite` remains the top-level aggregator.

- option parsing, option failure diagnostics, original argument indexes, and
  `--` handling;
- program source resolution, including empty direct programs, multiple `-f`
  files, empty files, final-newline separation, and `-f` operand handling;
- operand classification for files, `-`, valid runtime assignments, and paths
  containing `=`;
- `awklib` execution integration for fields, `BEGIN`, regular-expression
  patterns, arithmetic, built-ins, `ENVIRON`, `ARGV`, `ARGC`, `getline < file`,
  `command | getline`, standard output, and live redirected writes;
- controlled host I/O failures for stdin, stdout, stderr, program files, input
  files, redirection open failures, and redirection write failures;
- localized diagnostics, unsupported-locale fallback, catalog syntax policy,
  placeholder compatibility, and diagnostic escaping;
- process-level execution of the installed `awk` binary for help, version,
  direct programs, `-f`, `-F`, `-v`, parse failures, multiple input files,
  dash-leading filenames after `--`, runtime assignment `ARGV`, environment
  propagation to `ENVIRON`, explicit standard-input EOF, non-empty
  standard-input data, redirection, and redirected-output failures.
- conformance manifest validation for supported behavior, documented
  differences, and unsupported `awklib` cases.

The in-memory `Awk_CLI.Invocation_Context` lets tests provide arguments,
standard input, virtual files, environment entries, injected stream failures,
and captured writes without spawning the real executable. It also exposes the
last structured diagnostic identifier, category, and severity for tests that
should not depend only on rendered text.

The workflow command `./bin/awk_workflows verify` builds root and tests in
development mode, runs AUnit, validates crate metadata, validates required docs,
validates English and Danish shard catalogs, checks every supported European
state-language locale in the combined catalog, checks catalog placeholders and default
locale policy, runs translation consistency checks, validates the conformance
manifest, renders diagnostics for every supported locale, checks localized UTF-8 process rendering, checks exit-status and option/help documentation drift, checks the
package manifest policy, checks public GNATdoc coverage, checks local Alire workspace pins, checks adapter
isolation through parsed Ada `with` clauses, rejects
handwritten ANSI code tokens in production source while allowing the diagnostic
sanitizer to recognize ESC for escaping, rejects system-AWK fallback code
tokens in production source, verifies command-line access stays in the main
containment boundary or platform adapter, rejects direct `GNAT.OS_Lib`,
`GNAT.Expect`, and `/bin/sh` production use in favor of `hostkit`, rejects
shell/script workflow files, and runs an Alire install-boundary check into a
temporary prefix.

The release workflow runs the mandatory test and policy gates with release
builds, requires a clean git working tree, and packages the executable, message
catalogs, license, and documentation with byte counts and FNV-1a-64 checksums.

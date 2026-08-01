# Testing

Tests are implemented in the `tests` child Alire crate with AUnit. Test tooling is Ada code.

The primary suite is `awk_tests_main`. It exercises the option parser, program
source resolution, operand classification, the `awklib` execution adapter, the
in-memory `Awk_CLI.Invocation_Context` runner, compatibility-registry coverage,
catalog key coverage, locale separation, and process-level smoke tests for
version, help, usage failure, named-file input, `-f`, `-F`, `-v`, parse failure,
multiple files, and redirected output. It also verifies CLI-provided
`ARGV`/`ARGC` ordering and the documented captured-redirection append
limitation.

The invocation context lets tests provide arguments, standard input, virtual
files, environment entries, and injected output failures without spawning the
real executable.

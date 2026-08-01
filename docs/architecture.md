# Architecture

The CLI owns host integration: command-line parsing, program-file loading,
standard input and named input files, environment collection, `ARGV`/`ARGC`
construction, diagnostics, localization, terminal styling, process exit
statuses, and materializing captured redirections.

`awklib` owns AWK syntax and runtime semantics: lexical analysis, parsing,
expressions, records, fields, arrays, built-ins, regular expressions, `BEGIN`,
`END`, `getline`, printing, and redirection behavior. The CLI does not rewrite
AWK source or emulate missing interpreter behavior.

Production adapter boundaries:

- `Awk_CLI.Execution` is the only production package that directly depends on
  `awklib` interpreter APIs.
- `Awk_CLI.Localization` is the only production package that directly depends
  on `messages`.
- `Awk_CLI.Output` is the only production package that directly depends on
  `terminal_styles`.
- `Awk_CLI.Platform` isolates process arguments, streams, files, locale,
  catalog path lookup, and environment interaction.

`Awk_CLI.Run` coordinates a complete invocation through explicit result paths:
parse options, resolve program source, classify operands, load inputs, collect
environment, execute `awklib` once, materialize redirections, forward standard
output, and render controlled diagnostics on failure.

V1 is memory-oriented because the resolved `awklib` API is memory-oriented. The
CLI may hold complete program source, standard input, named input files,
captured standard output, and captured redirected output in memory. Redirections
are materialized after interpretation from captured results rather than written
as live streaming output.

The in-memory `Invocation_Context` is the primary test seam. It supplies
arguments, files, standard input, environment entries, output failures, and
captured writes without duplicating production command-line or execution logic.

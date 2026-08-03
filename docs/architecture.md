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
- `Awk_CLI.Platform` is the only production package that directly depends on
  `hostkit`. It isolates process arguments, streams, files, host shell command
  execution for `command | getline`, native locale lookup, temporary-path
  selection, catalog path lookup, and process environment enumeration.
  `Awk_CLI.Platform` also contains the remaining local byte-buffer and exact
  standard-stream helpers until `hostkit` exposes an equivalent public API with
  byte preservation, partial-write handling, binary-mode support, and explicit
  flush failure reporting.

The command-execution path is not an AWK fallback. `awklib` parses and evaluates
`command | getline`; the CLI only supplies the host command runner requested by
the awklib callback. No CLI package may inspect AWK source to discover command
strings or invoke a shell when awklib did not request that callback.

The `Awk_CLI` specs are documented because they are visible to the executable
and test crate, but they are internal CLI infrastructure rather than a stable
reusable library API. Compatibility commitments apply to the installed
`awk` executable and documented command-line behavior. Root `Awk_CLI` exposes
process initialization, context reset, and `Run`; deterministic in-memory test
controls live in the tests-crate child package `Awk_CLI.Testing`.

`Awk_CLI.Run` coordinates the top-level command flow: initialize localization,
parse options, handle help/version short circuits, render diagnostics, and
return stable exit statuses. `Awk_CLI.Invocation` owns ordinary parsed AWK
program runs: resolve program source, classify operands, collect environment
through the platform adapter, execute `awklib` once, forward standard output,
and materialize live redirection writes.

V1 remains partly memory-oriented for program source, in-memory test fixtures,
auxiliary `getline < file` fixtures, and in-memory command-output fixtures. The
main input is callback-driven: process named files are opened when their operand
is reached, read in chunks, and passed to `awklib`
`Run_Text_Streaming`, while process standard input is consumed only when an
implicit or explicit standard-input operand is reached. AWK record splitting,
`command | getline` semantics, standard output production, and redirected write
mode remain owned by `awklib`.
The execution adapter reports
`Awk_CLI.Execution.Supports_Streaming_Execution = True`. The adapter reports
`Awk_CLI.Execution.Supports_Redirection_Append_Mode = True`, because
`awklib` now provides live redirected write callbacks with append/truncate mode.
The presentation layer passes destination terminal state to `terminal_styles`,
so help on standard output and diagnostics on standard error can make
independent automatic color decisions.

The in-memory `Invocation_Context` is the primary test seam. The tests-crate
child package `Awk_CLI.Testing` supplies arguments, files, standard input,
environment entries, output failures, captured command output, and write
inspection without duplicating production command-line or execution logic.

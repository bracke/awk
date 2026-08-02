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
parse options, resolve program source, classify operands, collect environment,
execute `awklib` once, forward standard output, materialize live redirection
writes, and render controlled diagnostics on failure.

V1 remains partly memory-oriented for program source, in-memory test fixtures,
and auxiliary `getline < file` content that `awklib` accepts through a
registration map. The main input is callback-driven: process named files are opened
when their operand is reached, read in chunks, and passed to `awklib`
`Run_Text_Streaming`, while process standard input is consumed only when an
implicit or explicit standard-input operand is reached. AWK record splitting,
standard output production, and redirected write mode remain owned by `awklib`.
The execution adapter reports
`Awk_CLI.Execution.Supports_Streaming_Execution = True`. The adapter reports
`Awk_CLI.Execution.Supports_Redirection_Append_Mode = True`, because
`awklib` now provides live redirected write callbacks with append/truncate mode.

The in-memory `Invocation_Context` is the primary test seam. It supplies
arguments, files, standard input, environment entries, output failures, and
captured writes without duplicating production command-line or execution logic.

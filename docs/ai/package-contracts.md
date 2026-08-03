# Package Contracts

Only `Awk_CLI.Execution` may call `awklib`. Only `Awk_CLI.Localization` may call `messages`. Only `Awk_CLI.Output` may call `terminal_styles`. Only `Awk_CLI.Platform` may call `hostkit`.
Only `Awk_CLI.Platform` may enumerate process-global environment variables;
`Awk_CLI.Environment` owns only normalized ENVIRON data representation.

`command | getline` is an awklib-owned runtime feature. The CLI may provide the
host command-execution service only through the awklib callback path:
`Awk_CLI.Execution` receives the callback request from awklib, and
`Awk_CLI.Platform` performs the host process interaction through `hostkit`.
No other package may parse AWK command strings, evaluate AWK expressions,
discover command-getline source text, or invoke a shell as a fallback for AWK
execution.

`Awk_CLI.Compatibility` owns structured compatibility-registry data. It must
not call interpreter APIs or emulate AWK behavior.

Root `Awk_CLI` owns process initialization, context reset, and top-level
execution. `Awk_CLI.Testing` owns deterministic in-memory context mutation and
inspection for tests and must live in the tests crate; production packages must
not depend on it.

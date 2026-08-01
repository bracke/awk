# Package Contracts

Only `Awk_CLI.Execution` may call `awklib`. Only `Awk_CLI.Localization` may call `messages`. Only `Awk_CLI.Output` may call `terminal_styles`.

`Awk_CLI.Compatibility` owns structured compatibility-registry data. It must
not call interpreter APIs or emulate AWK behavior.

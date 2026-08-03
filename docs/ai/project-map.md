# Project Map

Root executable: `src/main/awk.adb`. Testable runner: `Awk_CLI.Run`.
Parsed AWK invocation executor: `Awk_CLI.Invocation`. Interpreter bridge:
`Awk_CLI.Execution`. In-memory context controls: tests-crate child package
`Awk_CLI.Testing`.

Requirement-to-evidence mapping lives in `docs/ai/traceability.md`.

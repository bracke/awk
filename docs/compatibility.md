# Compatibility

This executable follows the traditional POSIX `awk` command-line workflow where
`awklib` exposes the needed behavior. It does not claim complete POSIX
conformance. The CLI does not implement a second AWK parser, evaluator, regular
expression engine, field engine, source rewriter, or custom record loop.

Accepted limitations are tracked in the Ada registry `Awk_CLI.Compatibility`.
Each entry lists the affected area, status, source of limitation, and the
closest current test reference.

| ID | Area | Status | Source | Test reference | Description |
| --- | --- | --- | --- | --- | --- |
| `AWK-COMPAT-REGEX-001` | Regular expressions | Supported with documented difference | `awklib 0.1.0` and `regexp` | `context expressions regex builtins` | Regular-expression matching follows resolved `awklib` and `regexp` behavior rather than adding CLI-side matching. |
| `AWK-COMPAT-GETLINE-001` | Getline | Unsupported by awklib | `awklib 0.1.0` | `compatibility registry` | Main-input `getline` from `BEGIN` is inherited from `awklib`. |
| `AWK-COMPAT-GETLINE-002` | Getline | Unsupported by awklib | `awklib 0.1.0` | `compatibility registry` | `command | getline` is not implemented by the CLI. |
| `AWK-COMPAT-UTF8-001` | Encoding | Supported with documented difference | `awklib 0.1.0` | `compatibility registry` | Malformed UTF-8 handling is inherited from `awklib`. |
| `AWK-COMPAT-PRINTF-001` | Output formatting | Supported with documented difference | `awklib 0.1.0` | `compatibility registry` | `%c` field-width behavior is inherited from `awklib`. |
| `AWK-COMPAT-ASSIGNMENT-001` | Command line | Supported with documented difference | `awklib 0.1.0` Arguments API; `Awk_CLI.Execution.Supports_Positional_Runtime_Assignments = False` | `context runtime assignment limitation` | `awklib` does not expose exact positional runtime-assignment execution. The CLI preserves operand spelling/order in `ARGV` but does not emulate a custom record loop. |
| `AWK-COMPAT-REDIRECTION-001` | Redirection | Supported with documented difference | `awklib 0.1.0` Output_Files API | `context append redirection limitation` | `awklib` returns captured final redirected output without exposing whether a target used `>` or `>>`, so the CLI materializes final files after interpretation and cannot preserve append intent without parsing AWK source. |

An `awklib` dependency update requires rebuilding, running all tests, reviewing
upstream behavior, updating this registry and document, and changing test
expectations only where the resolved interpreter behavior actually changes.

# Compatibility

This executable follows the traditional POSIX `awk` command-line workflow where `awklib` exposes the needed behavior. It does not claim complete POSIX conformance.

Accepted limitations:

- `AWK-COMPAT-REGEX-001`: regular-expression matching follows the resolved `awklib` and `regexp` behavior rather than adding CLI-side matching.
- `AWK-COMPAT-UTF8-001`: malformed UTF-8 handling is inherited from `awklib`.
- `AWK-COMPAT-PRINTF-001`: `%c` field-width behavior is inherited from `awklib`.
- `AWK-COMPAT-GETLINE-001`: main-input `getline` from `BEGIN` is inherited from `awklib`.
- `AWK-COMPAT-GETLINE-002`: `command | getline` is not implemented by the CLI.
- `AWK-COMPAT-ASSIGNMENT-001`: `awklib` does not expose exact positional runtime-assignment execution. The CLI preserves operand spelling/order in ARGV but does not emulate a custom record loop.
- `AWK-COMPAT-REDIRECTION-001`: `awklib` returns captured final redirected output without exposing whether a target used `>` or `>>`, so the CLI materializes final files after interpretation and cannot preserve append intent without parsing AWK source.

The same registry is maintained as Ada data in `Awk_CLI.Compatibility` so tests
and release tooling can validate stable IDs against this documentation.

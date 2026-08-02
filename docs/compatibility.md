# Compatibility

This executable follows the traditional POSIX `awk` command-line workflow where
`awklib` exposes the needed behavior. It does not claim complete POSIX
conformance. The CLI does not implement a second AWK parser, evaluator, regular
expression engine, field engine, source rewriter, or custom record loop.

Accepted limitations are tracked in the Ada registry `Awk_CLI.Compatibility`.
Each entry lists the affected area, status, source of limitation, and the
closest current test reference.

No current compatibility-registry entries are active for the resolved
`awklib` version.

| ID | Area | Status | Source | Test reference | Description |
| --- | --- | --- | --- | --- | --- |

An `awklib` dependency update requires rebuilding, running all tests, reviewing
upstream behavior, updating this registry and document, and changing test
expectations only where the resolved interpreter behavior actually changes.

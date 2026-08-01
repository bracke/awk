# Diagnostics

Exit statuses are stable: `0` success, `1` interpreter failure, `2` usage error, `3` host I/O failure, and `70` internal failure.

CLI diagnostics are localized and terminal-control-safe. AWK output is never escaped or styled.

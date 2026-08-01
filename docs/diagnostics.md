# Diagnostics

Exit statuses are stable: `0` success, `1` interpreter failure, `2` usage error, `3` host I/O failure, and `70` internal failure.

CLI diagnostics are localized and terminal-control-safe. AWK output is never escaped or styled.

Styling is produced only through `terminal_styles`. `--color=auto` follows the
resolved `terminal_styles` policy, including `NO_COLOR` and stdout terminal
detection. The current dependency API exposes a process-wide stdout-oriented
auto policy, so independent stderr auto detection is documented as an
integration limitation until `terminal_styles` provides a separate destination
policy hook.

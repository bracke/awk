# Diagnostics

Expected operational failures are represented as structured diagnostics until
final rendering. Categories include usage, program source, input, output,
interpreter, environment, platform, and internal failures.

Rendered CLI diagnostics use this shape:

```text
awk: error: localized primary message
source-name:line:column
interpreter or host detail
hint: localized hint
```

Source locations are optional and are currently used by CLI-owned diagnostics
when available. Interpreter-provided details are preserved as technical detail
without parsing or rewriting AWK source.

Exit statuses are stable:

| Status | Meaning |
| --- | --- |
| `0` | Success, `--help`, or `--version` |
| `1` | AWK parse or runtime failure |
| `2` | Invalid command-line invocation |
| `3` | Host input/output failure |
| `70` | Unexpected internal software failure |

CLI diagnostics are localized and terminal-control-safe. Untrusted diagnostic
values such as option text, filenames, source names, and interpreter details
escape embedded newlines, carriage returns, tabs, ESC, and other control
characters. AWK standard output and redirected output are never escaped,
localized, styled, prefixed, or reformatted.

Styling is produced only through `terminal_styles`. `--color=auto` follows the
resolved `terminal_styles` policy, including `NO_COLOR` and stdout terminal
detection. The current dependency API exposes a process-wide stdout-oriented
auto policy, so independent stderr auto detection is documented as an
integration limitation until `terminal_styles` provides a separate destination
policy hook.

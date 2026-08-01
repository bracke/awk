# Command-Line Reference

Invocation forms:

```text
awk [options] 'program' [operand...]
awk [options] -f program-file [-f program-file...] [operand...]
```

Supported options are `-F sep`, `-Fsep`, `-v name=value`, `-vname=value`,
`-f file`, `-ffile`, `--help`, `--version`, `--color=auto|always|never`, and
`--`.

The final `-F` value wins. All `-v` assignments are applied in command-line
order before `BEGIN`. All `-f` files are loaded in command-line order and
concatenated with a safe line separator when needed. If any `-f` option is
present, the first remaining operand is not treated as a direct program; it is
an AWK operand.

`--` ends option processing. Filenames beginning with `-` work after `--`.
`-f -` is intentionally unsupported because standard input is reserved for AWK
data.

Runtime assignment operands are recognized only when the name before the first
`=` matches `[A-Za-z_][A-Za-z0-9_]*`. The complete value after the first `=` is
preserved. Other operands are named input files except `-`, which selects the
single standard-input stream at that position.

When no explicit input file or `-` operand is present, standard input is used
implicitly. Repeated `-` operands are allowed; after the first one consumes the
available standard input, later uses observe end of file.

Exit statuses are `0` for success, `1` for interpreter parse/runtime failures,
`2` for invalid command-line invocation, `3` for host input/output failures,
and `70` for unexpected internal failures.

This executable does not claim complete POSIX conformance. AWK language and
runtime behavior are the behavior exposed by the resolved `awklib` version.

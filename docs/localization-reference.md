# Localization Reference

Translations are reviewed against comparable text from established AWK
implementations and specifications. This repository does not execute those
implementations during tests, and no external AWK executable is required for
release verification.

Reference text families:

- POSIX `awk` utility text: invocation forms, operand wording, `-F`, `-f`,
  `-v`, standard input, file operands, assignment operands, and exit behavior.
- GNU awk user documentation and help text: user-facing option descriptions,
  program-file wording, command-line assignment wording, standard input wording,
  and compatibility warnings.
- BWK awk / one-true-awk usage text: traditional option names, concise usage
  phrasing, and file operand terminology.
- BusyBox awk help text: compact command-line wording suitable for small
  terminals.

Reviewers compare translated catalog entries against those references for
natural target-language terminology while preserving this project's exact
behavior. The references inform wording only; `awklib` remains the sole source
of AWK language and runtime behavior.

Protected AWK and CLI terms must remain literal unless the CLI syntax itself
changes:

```text
awk
awklib
-F
-v
-f
--help
--version
--color
--
ARGV
ARGC
ENVIRON
BEGIN
END
getline
print
printf
POSIX
MIT
```

Reference comparison checklist:

- Usage text should resemble conventional AWK usage descriptions without
  claiming complete POSIX conformance.
- Option descriptions should match this CLI's implemented behavior, especially
  final `-F` wins, ordered `-v`, ordered `-f`, and `--` termination.
- Operand text should preserve the distinction between input files, `-` for
  standard input, and runtime assignments.
- Compatibility text should state that language/runtime behavior follows
  `awklib` and documented project limitations.
- Translations should not contain raw English fallback sentences unless the
  target locale intentionally uses the same technical token or syntax.

Machine-checked reference cues:

```text
awk.help.summary: awk, awklib, POSIX
awk.help.usage.direct_program: awk
awk.help.usage.program_files: awk, -f
awk.help.options.field_separator: -F, FS
awk.help.options.variable: -v, BEGIN
awk.help.options.program_file: -f, AWK
awk.help.options.color: --color=auto|always|never
awk.help.options.help: --help
awk.help.options.version: --version
awk.help.options.terminator: --
awk.help.operands: -, [A-Za-z_][A-Za-z0-9_]*
awk.help.stdin: -
awk.help.exit_statuses: 0, 1, 2, 3, 70
awk.help.compatibility.awklib_limitations: POSIX, AWK, awklib, getline
```

The release workflow uses these cues as a minimum evidence check for every
supported locale. They are not a complete translation-quality metric, but they
make reference comparison visible in the executable release gate.

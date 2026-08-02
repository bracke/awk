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

<!-- generated:awk-acceptance -->
# Final Acceptance

This file records the Normative acceptance gates for `awk`.

Runtime:

- Alire binary crate builds with Ada 2022.
- Installed executable is named `awk`.
- AWK language execution is delegated to `awklib`.
- Direct program, `-f`, `-F`, `-v`, standard input, named input, `ARGV`,
  `ARGC`, `ENVIRON`, getline, and redirection integration tests pass.

Output:

- AWK standard output and redirected output are not localized, styled, escaped,
  prefixed, or reformatted by CLI presentation code.
- CLI diagnostics and help text are localized through `messages`.
- CLI-owned styling is produced through `terminal_styles`.

Host integration:

- Platform-dependent process, terminal, filesystem, locale, and command access
  stays isolated behind `Awk_CLI.Platform` and `hostkit`.
- Operational failures use structured diagnostics and stable exit statuses.
- Untrusted diagnostic values are escaped without altering AWK output.

Testing:

- AUnit, in-memory context, process-boundary, compatibility, catalog, and
  conformance tests pass.
- Accepted compatibility differences are registered and documented.
- Source-policy gates verify adapter boundaries, no shell/script workflow
  logic, no handwritten terminal escapes, and no external AWK fallback.

Release:

- Metadata, dependency pins, required documentation, catalog completeness,
  exit-status documentation, option/help documentation, package-resource
  manifest policy, install-boundary checks, and traceability checks pass.
- Release builds use Alire release profiles and require a clean git working
  tree.
- Packaging includes the executable, message catalogs, license, compatibility
  documentation, and deterministic FNV-1a-64 manifest entries.

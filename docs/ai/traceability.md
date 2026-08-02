# Requirement Traceability

This matrix maps the original implementation prompt sections to the current
source, tests, workflow gates, and documentation evidence. It is an audit aid;
the executable behavior remains defined by the installed `awk` command, the
resolved `awklib` behavior, and the release workflow.

| Section | Requirement Area | Primary Evidence |
| --- | --- | --- |
| 1 | Project identity | `alire.toml`, `awk.gpr`, `tests/alire.toml`, `tests/awk_tests.gpr`, `tests/src/awk_workflows.adb` metadata checks |
| 2 | Core compatibility position | `README.md`, `docs/compatibility.md`, `src/library/awk_cli-compatibility.*`, `tests/src/awk_tests-compatibility.adb` |
| 3 | Architectural boundary | `docs/architecture.md`, `docs/ai/package-contracts.md`, source-policy checks in `tests/src/awk_workflows.adb` |
| 4 | Repository structure | root docs, `src/main`, `src/library`, `resources/messages`, `tests/src`, `tests/fixtures`, `tests/conformance` |
| 5 | Alire requirements | root and test `alire.toml`, local pin checks in `tests/src/awk_workflows.adb` |
| 6 | Command-line interface | `src/library/awk_cli-options.*`, `tests/src/awk_tests-cli_options.adb`, process tests in `tests/src/awk_tests-process.adb` |
| 7 | Program source resolution | `src/library/awk_cli-programs.*`, `tests/src/awk_tests-program_sources.adb`, process `-f` tests |
| 8 | Assignment recognition | `Awk_CLI.Options.Is_Assignment_Text`, `Awk_CLI.Operands.Classify`, option and operand tests |
| 9 | Input operands | `src/library/awk_cli-operands.*`, `src/library/awk_cli-inputs.*`, `tests/src/awk_tests-inputs.adb`, stdin process tests |
| 10 | Memory and streaming model | `docs/architecture.md`, `Awk_CLI.Execution.Supports_Streaming_Execution`, streaming adapter tests |
| 11 | Environment, ARGV, and ARGC | `src/library/awk_cli-environment.*`, execution adapter, context and process environment/ARGV tests |
| 12 | Auxiliary input and getline | `Awk_CLI.Execution.Execute_Live_Input`, command and auxiliary getline tests, compatibility registry |
| 13 | Execution adapter | `src/library/awk_cli-execution.*`, adapter isolation workflow checks, `tests/src/awk_tests-execution.adb` |
| 14 | Standard output | `Awk_CLI.Execution` live output callbacks, `Awk_CLI.Platform.Write_Standard_Output`, output/styling tests |
| 15 | Output redirection | `src/library/awk_cli-redirections.*`, live redirection callbacks, redirection unit and process tests |
| 16 | Localization | `src/library/awk_cli-localization.*`, `resources/messages`, catalog policy and localization tests |
| 17 | Terminal styling | `src/library/awk_cli-output.*`, terminal style adapter checks, terminal style and process color tests |
| 18 | Diagnostic model | `src/library/awk_cli-diagnostics.*`, diagnostic rendering tests, `docs/diagnostics.md` |
| 19 | Exit status registry | `Awk_CLI.Diagnostics` exit constants, diagnostic status tests, process failure tests |
| 20 | Exception policy | `src/main/awk.adb`, adapter exception containment, internal diagnostic status tests |
| 21 | Host abstraction and testability | `Awk_CLI.Invocation_Context`, context tests, process adapter tests |
| 22 | Platform adapter | `src/library/awk_cli-platform.*`, adapter isolation docs and source-policy checks |
| 23 | Internal package responsibilities | package specs under `src/library`, `docs/ai/package-contracts.md`, source-policy checks |
| 24 | Help output | `Awk_CLI.Output.Help`, message catalogs, process help tests |
| 25 | Version output | `Awk_CLI.Output.Version`, `config/awk_config.ads`, process version tests |
| 26 | Test crate | `tests/alire.toml`, `tests/awk_tests.gpr`, `tests/src/awk_tests-suite.adb` |
| 27 | In-memory test harness | `Awk_CLI.Invocation_Context`, `tests/src/awk_tests-context.adb`, support helpers |
| 28 | Option parser tests | `tests/src/awk_tests-cli_options.adb`, usage process tests |
| 29 | Program source tests | `tests/src/awk_tests-program_sources.adb`, program fixture files |
| 30 | Operand tests | `tests/src/awk_tests-operands.adb`, input ordering tests |
| 31 | AWK integration tests | `tests/src/awk_tests-context.adb`, `tests/src/awk_tests-process.adb`, conformance cases |
| 32 | Accepted limitation tests | `src/library/awk_cli-compatibility.*`, `docs/compatibility.md`, compatibility tests |
| 33 | Localization tests | `tests/src/awk_tests-localization.adb`, `tests/src/awk_catalog_policy.adb`, catalog workflow checks |
| 34 | Styling tests | `tests/src/awk_tests-terminal_styles.adb`, process color tests, source-policy ANSI checks |
| 35 | I/O failure tests | `tests/src/awk_tests-inputs.adb`, `tests/src/awk_tests-redirections.adb`, redirected-output process failure test |
| 36 | Process-level tests | `tests/src/awk_tests-process.adb`, install-boundary checks in `tests/src/awk_workflows.adb` |
| 37 | Regression policy | `docs/testing.md`, compatibility/conformance IDs, AUnit package registration checks |
| 38 | Compatibility registry | `src/library/awk_cli-compatibility.*`, `docs/compatibility.md`, compatibility workflow checks |
| 39 | Tooling requirements | `tests/src/awk_workflows.adb`, `project_tools` dependencies, source-policy script checks |
| 40 | Development build policy | development profile settings in `alire.toml`, build/verify workflows |
| 41 | Release build policy | release command path in `tests/src/awk_workflows.adb`, `docs/releasing.md`, package manifest checks |
| 42 | Source style | Ada 2022 project files, source-policy checks, package-boundary docs |
| 43 | Documentation requirements | required docs list and content checks in `tests/src/awk_workflows.adb` |
| 44 | Core invariants | `docs/ai/invariants.md`, source-policy checks, output/localization/styling tests |
| 45 | Prohibited designs | `docs/ai/prohibited-designs.md`, source-policy checks for awklib, ANSI, scripts, and AWK fallback |
| 46 | Security requirements | `SECURITY.md`, diagnostic escaping tests, environment confidentiality tests |
| 47 | Performance requirements | streaming callbacks, builder-style Ada containers, architecture memory model notes |
| 48 | Implementation order | git history, passing `verify` and `release`, maintained runnable executable |
| 49 | Definition of done | `alr exec -- ./bin/awk_workflows release`, this traceability matrix, clean working tree |

Known remaining release-hardening item: the development workspace still uses
local Alire pins and a dev dependency constraint for `terminal_styles`; those
must be reviewed before publishing outside this workspace.

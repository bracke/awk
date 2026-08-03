# Agent Notes

Maintain the package boundaries in `docs/ai/package-contracts.md`. Do not add a
second AWK parser, evaluator, regex engine, field engine, or shell-based
fallback. Host command execution is allowed only for awklib's `command |
getline` callback path through `Awk_CLI.Platform` and `hostkit`.

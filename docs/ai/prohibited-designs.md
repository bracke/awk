# Prohibited Designs

Do not implement a second AWK parser, evaluator, regex engine, field engine,
source rewriter, system-AWK fallback, hard-coded user-facing English strings,
handwritten ANSI sequences, or shell/Python/Make/Node workflow logic.

Do not invoke a shell to compensate for missing AWK interpreter behavior. The
only permitted host shell use is the `command | getline` service requested by
awklib through its command callback and isolated behind `Awk_CLI.Platform` and
`hostkit`.

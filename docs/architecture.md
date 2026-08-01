# Architecture

The CLI owns host integration: arguments, files, standard input/output, diagnostics, localization, styling, environment, ARGV/ARGC construction, and materializing captured redirections.

`Awk_CLI.Execution` is the only production package that directly depends on `awklib` interpreter APIs.

# Localization

CLI-authored user-facing text is rendered through `messages` using keys under `awk.`. English and Danish catalogs are included.

The Ada workflow validates the required English and Danish key set in the
combined catalog and locale shards. Required messages must be non-empty, and
English/Danish placeholder sets must match for each key.

Locale never changes AWK source, input, output, numeric conversion, filenames, variable names, variable values, or regular-expression semantics.

# Localization

CLI-authored user-facing text is rendered through `messages` using keys under `awk.`. English and Danish catalogs are included.

The Ada workflow validates the required English and Danish key set in the
combined catalog and locale shards. Required messages must be non-empty, and
English/Danish placeholder sets must match for each key.

Unsupported locales fall back through the `messages` runtime to the catalog
default locale. If a requested message key cannot render but the catalog is
otherwise usable, the CLI renders the catalog-backed
`awk.internal.localization_failed` message instead of exposing the raw key as
ordinary prose. A raw escaped key is reserved only as a last-resort containment
path when even the fallback message cannot render.

Locale never changes AWK source, input, output, numeric conversion, filenames, variable names, variable values, or regular-expression semantics.

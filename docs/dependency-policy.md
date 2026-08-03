# Dependency Policy

The repository currently supports a workspace release model. Root dependencies
use deliberate constraints, and local pins bind the workspace to sibling crates
that are developed and verified together.

Current direct dependency policy:

| Crate | Constraint | Workspace pin | Release note |
| --- | --- | --- | --- |
| `awklib` | `~0.1.0` | `../awklib` | Interpreter dependency; update requires compatibility review. |
| `terminal_styles` | `=0.1.0-dev` | `../terminal_styles` | Development dependency version; publish is blocked until a non-dev crate release exists. |
| `messages` | `~0.1.0` | `../messages` | Localization dependency; catalog behavior is tested in this crate. |
| `hostkit` | `=0.1.0-dev` | `../hostkit` | Platform-access dependency; shell, native locale, and host temporary-directory behavior stay behind `Awk_CLI.Platform`. |

## Hostkit Stream Helpers

`Awk_CLI.Platform` uses `hostkit` for platform-specific host services. The
small local `Byte_IO` helper and standard-stream write loop remain in `awk`
because `hostkit` does not currently expose a public exact standard-stream
write helper or stream-to-string helper that matches this executable's needs.
Hostkit stream helper boundary: local exact stream helpers remain in
`Awk_CLI.Platform` until `hostkit` exposes matching public APIs.

These helpers may move to `hostkit` when a reusable API preserves exact bytes,
handles partial writes, supports binary standard streams, flushes failures
deterministically, and does not style, localize, or otherwise transform AWK
output. Until then they are host-integration glue only, not AWK language or
runtime logic.

The tests crate pins only workspace tooling dependencies:

| Crate | Constraint | Workspace pin | Release note |
| --- | --- | --- | --- |
| `awk` | `~0.1.0` | `..` | Relative pin to the root crate under test. |
| `project_tools` | `~0.1.0` | `../../project_tools` | Shared Ada workflow tooling. |
| `messages` | `~0.1.0` | `../../messages` | Catalog consistency checks use the public messages APIs. |

No direct dependency may use an unrestricted wildcard constraint in a release
candidate. The workflow validates the expected local workspace pins so the
release result is reproducible for this workspace.

Publish readiness is a separate gate from the current workspace release. Before
publishing outside this workspace:

1. Release or select non-dev `terminal_styles` and `hostkit` versions.
2. Replace `terminal_styles = "=0.1.0-dev"` and `hostkit = "=0.1.0-dev"`
   with reviewed compatible non-dev constraints.
3. Remove root local pins, or move them to a non-published local development
   manifest if Alire packaging policy requires it.
4. Refresh `alire/alire.lock`.
5. Run `alr exec -- ./bin/awk_workflows verify` and
   `alr exec -- ./bin/awk_workflows release`.
6. Review `docs/compatibility.md`, `docs/ai/traceability.md`, and
   `CHANGELOG.md`.

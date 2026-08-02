# Workflows

Use Ada tooling in the `tests` crate for build, test, verify, docs, clean, package, and release workflows.

The workflow executable is `awk_workflows` and accepts:

```text
build
test
verify
docs
clean
package
release
```

It uses `project_tools` process helpers for child-process execution and does
not rely on shell scripts.

Nested Alire builds are launched through a scrubbed environment so `alr exec`
dependency-prefix variables from the outer process cannot conflict with the
root and tests crate resolutions.

`verify` also runs source-policy checks for adapter isolation through parsed
Ada `with` clauses, no handwritten ANSI code tokens in production source
except diagnostic ESC recognition for escaping, no external AWK fallback code
tokens in production source, and expected local
Alire workspace pins.

`release` requires a clean git working tree, builds root and tests with
`--release --profiles=*=release`, runs the same mandatory checks, and packages
only after those gates pass.

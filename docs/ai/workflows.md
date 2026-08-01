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

`verify` also runs source-policy checks for adapter isolation, no direct ANSI
emission in presentation code, and no external AWK fallback references in
production source.

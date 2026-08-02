# Building

Use Alire:

```sh
alr build --development
```

The child test crate also provides `awk_workflows` for build, test, verify,
package, and release workflow gates.

`build`, `test`, and `verify` use development builds. `verify` also checks the
crate metadata, local Alire workspace pins, conformance manifest, source-policy
invariants, and Alire install boundary. `clean` removes build outputs,
including the workflow executable itself, and generated release packages under
`dist`; run `alr build` in `tests` before invoking another workflow command
after `clean`. `release` requires a clean git working tree and uses Alire
release profiles.

Dependency constraints and local workspace pins are documented in
`docs/dependency-policy.md`. The current workflow release is reproducible inside
this workspace; publishing outside the workspace requires the separate publish
readiness checklist in that document.

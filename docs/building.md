# Building

Use Alire:

```sh
alr build --development
```

The child test crate also provides `awk_workflows` for build, test, verify,
package, and release workflow gates.

`build`, `test`, and `verify` use development builds. `verify` also checks the
crate metadata, conformance manifest, source-policy invariants, and Alire
install boundary. `release` requires a clean git working tree and uses Alire
release profiles.

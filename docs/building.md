# Building

Use Alire:

```sh
alr build --development
```

The child test crate also provides `awk_workflows` for build, test, verify,
package, and release workflow gates.

`build`, `test`, and `verify` use development builds. `release` requires a
clean git working tree and uses Alire release profiles.

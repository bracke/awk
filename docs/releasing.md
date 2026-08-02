# Releasing

Release verification must require a clean git working tree, build root and
tests with Alire release profiles, run AUnit and process-level tests, validate
catalogs and compatibility documentation, package the executable, message
catalogs, license, and compatibility documentation, and fail on any mandatory
gate.

The current Ada workflow command is:

```text
cd tests
./bin/awk_workflows release
```

The release workflow invokes `alr -n build --release --profiles=*=release`;
it does not use `--development`. It also validates crate metadata, local Alire workspace pins,
dependency policy, the conformance manifest, source-policy
invariants, and an Alire install into a temporary prefix before packaging. It
creates `dist/awk-0.1.0` with the executable, license, README, changelog,
contribution and security notes, core user/developer documentation, AI-oriented
maintenance docs, the dependency policy, the traceability matrix, message
catalogs, and `MANIFEST.txt` containing byte counts and deterministic
FNV-1a-64 checksums for packaged files.

This is a workspace release, not a publish-ready Alire index release. See
`docs/dependency-policy.md` for the current local pins, the
`terminal_styles = "=0.1.0-dev"` and `hostkit = "=0.1.0-dev"` constraints,
and the separate publish readiness checklist.

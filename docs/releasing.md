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
it does not use `--development`. It creates `dist/awk-0.1.0` with the
executable, license, README,
compatibility documentation, message catalog, and `MANIFEST.txt` containing
byte counts and deterministic checksums for packaged files.

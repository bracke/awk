# Releasing

Release verification must build root and tests, run AUnit and process-level tests, validate catalogs and compatibility documentation, package the executable, message catalogs, license, and compatibility documentation, and fail on any mandatory gate.

The current Ada workflow command is:

```text
cd tests
./bin/awk_workflows release
```

It creates `dist/awk-0.1.0` with the executable, license, README,
compatibility documentation, message catalog, and `MANIFEST.txt` containing
byte counts and deterministic checksums for packaged files.

# awk

`awk` is an Ada command-line AWK implementation built on `awklib`. Its command-line workflow follows traditional POSIX `awk`; supported language and runtime behavior is limited to the resolved `awklib` version.

The program does not claim complete POSIX conformance.

## Usage

```sh
awk '{ print }' file.txt
awk -F, '{ print $2 }' data.csv
awk -v limit=10 '$1 > limit { print $0 }' input.txt
awk -f program.awk input.txt
```

If no input file is supplied, standard input is used. Use `--` before filenames beginning with `-`.

Build with Alire:

```sh
alr build --development
cd tests && alr build --development && ./bin/awk_tests
```

Limitations are documented in [docs/compatibility.md](docs/compatibility.md). The project is MIT licensed.

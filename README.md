<img src="https://raw.githubusercontent.com/gabyx/githooks/main/docs/githooks-logo.svg" style="margin-left: 20pt" align="right">

# Githooks for C++

This repository contains shared repository Git hooks for shell scripts in
`githooks/*` to be used with the
[Githooks Manager](https://github.com/gabyx/Githooks).

The following is included:

- Hook to format C++ files with `clang-format` (pre-commit). A configuration
  file to use in your repository is `config/.clang-format`.
- Hook to format CMake files with `cmake-format` (pre-commit).
- Hook to check for dead includes in C++ files (pre-commit).
- Hook to check for private includes pre-commit).
- Scripts to format/check all files according to the hooks.

<details>
<summary><b>Table of Content (click to expand)</b></summary>

<!-- TOC -->

- [Githooks for C++](#githooks-for-c)
  - [Requirements](#requirements)
  - [Installation](#installation)
  - [Hook: `pre-commit/1-format/.format-cpp.h`](#hook-pre-commit1-formatformat-cpph)
    - [Git Config Variables](#git-config-variables)
  - [Hook: `pre-commit/1-format/format-glsl.yaml`](#hook-pre-commit1-formatformat-glslyaml)
  - [Hook: `pre-commit/1-format/format-cmake.yaml`](#hook-pre-commit1-formatformat-cmakeyaml)
  - [Hook: `pre-commit/2-check/check-private-includes-cpp.yaml`](#hook-pre-commit2-checkcheck-private-includes-cppyaml)
  - [Hook: `pre-commit/2-check/check-no-dead-includes-cpp.yaml`](#hook-pre-commit2-checkcheck-no-dead-includes-cppyaml)
  - [Scripts](#scripts)
  - [Testing](#testing)

</details>

## Requirements

Run them
[containerized](https://github.com/gabyx/Githooks#running-hooks-in-containers)
where only `docker` is required.

If you want to run them non-containerized, make the following installed on your
system:

- `clang-format`
- `cmake-format`
- `bash`
- GNU `grep`
- GNU `sed`
- GNU `find`
- GNU `xargs`
- GNU `parallel` _[optional]_

This works with Windows setups too.

## Installation

The hooks can be used by simply using this repository as a shared hook
repository inside C++ projects.
[See further documentation](https://github.com/gabyx/githooks#shared-hook-repositories).

You should configure the shared hook repository in your project to use this
repos `main` branch by using the following `.githooks/.shared.yaml` :

```yaml
version: 1
urls:
  - https://github.com/gabyx/githooks-cpp.git@main`.
```

## Hook: `pre-commit/1-format/.format-cpp.h`

Formats C++ files with `clang-format`.

By settings the global Git config value `githooks-cpp.clangFormat` to the
`clang-format` dispatch utility, the correct `clang-format` version can be
selected. The dispatch utility dispatches to the different `clang-format`
versions depending on the header in the found clang format config file, that
means a `.clang-format` config can define the version to be used by the
following comment header:

```ini
# Version: 12.0.0
```

### Git Config Variables

- `githooks-cpp.clangFormat` : Auxiliary path to a `clang-format` executable
  (any Git config level).

## Hook: `pre-commit/1-format/format-glsl.yaml`

Same as `pre-commit/1-format/format-cpp.yaml`.

## Hook: `pre-commit/1-format/format-cmake.yaml`

Formats all `*.cmake` and `CMakeLists.txt` files by using
`configs/.cmake-format.json` as well as the `<repo-root>/cmake-format.json`
which can contain project-specific `additional_commands` overrides. This hook
needs [`cmake-format`](https://github.com/cheshirekow/cmake_format) installed.

Because CMake is a macro language, the formatter needs to know how to format
commands and therefore we use this repository's config in
`configs/.cmake-format.json`.

## Hook: `pre-commit/2-check/check-private-includes-cpp.yaml`

If a project uses merged header placement as described in
[PR1204R0](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2018/p1204r0.html)
and also complies more or less to the
[Pitchfork layout](https://api.csswg.org/bikeshed/?force=1&url=https://raw.githubusercontent.com/vector-of-bool/pitchfork/develop/data/spec.bs)
(at least for the `src` directory), this hook ensures that no private headers
defined as

- files in `src/<lib-name>.*/private/.*`
- files in `src/<lib-name>.*/details/.*`

are included in files `src/<other-lib-name>/.../.*`. Such includes are by
definition architectural design errors and can be enforced by this hook.

## Hook: `pre-commit/2-check/check-no-dead-includes-cpp.yaml`

Checks that no commented includes are found in C++ files.

## Scripts

The following scripts are provided:

- [`format-cpp-all.sh`](githooks/scripts/format-cpp-all.sh) : Script to format
  all C++ files in a directory recursively. See documentation.
- [`format-cmake-all.sh`](githooks/scripts/format-cmake-all.sh) : Script to
  format all CMake files in a directory recursively. See documentation.

They can be used in scripts by doing the following trick inside a repo which
uses this hook:

```shell
shellHooks=$(git hooks shared root ns:githooks-cpp)
"$shellHooks/githooks/scripts/<script-name>.sh"
```

## Testing

The containerized tests in `tests/*` are executed by

```bash
tests/test.sh
```

or only special tests steps by

```bash
tests/test.sh --seq 001..010
```

For showing the output also in case of success use:

```bash
tests/test.sh --show-output [other-args]
```

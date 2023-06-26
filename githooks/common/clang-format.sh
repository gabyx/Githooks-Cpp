#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2015


DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
. "$DIR/log.sh"
. "$DIR/version.sh"
. "$DIR/regex-cpp.sh"

# Assert that 'clang-format' (`=$1`) has version `[$2, $3)`.
function assertClangFormatVersion() {
    local expectedVersionMin="$1"
    local expectedVersionMax="$2"
    local exe="${3:-clang-format}"

    command -v "$exe" &>/dev/null ||
        die "Tool '$exe' is not installed."

    local version
    version=$("$exe" --version | sed -E "s@.* ([0-9]+\.[0-9]+\.[0-9]+).*@\1@")

    versionCompare "$version" ">=" "$expectedVersionMin" &&
        versionCompare "$version" "<" "$expectedVersionMax" ||
        die "Version of 'clang-format' is '$version' but should be '[$expectedVersionMin, $expectedVersionMax)'."

    printInfo "Version: clang-format '$version'."
    return 0
}

# Format a C++ file inplace.
function formatCppFile() {
    local clangFormatExe="$1"
    local file="$2"

    printInfo " - ✍ Formatting file: '$file'"
    "$clangFormatExe" -style=file -fallback-style=none -i "$file" 1>&2 ||
        {
            printError "'$clangFormatExe' failed for: '$file'"
            return 1
        }

    return 0
}

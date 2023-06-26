#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2015


DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
. "$DIR/log.sh"
. "$DIR/version.sh"

# Get the general Cmake file regex.
function getGeneralCMakeFileRegex() {
    echo '(.*CMakeLists\.txt|.*\.cmake)$'
}

# Assert that 'cmake-format' (`=$1`) has version `[$2, $3)`.
function assertCMakeFormatVersion() {
    local expectedVersionMin="$1"
    local expectedVersionMax="$2"
    local exe="${3:-cmake-format}"

    command -v "$exe" &>/dev/null ||
        die "Tool '$exe' is not installed."

    local version
    version=$("$exe" --version | sed -E "s@.* ([0-9]+\.[0-9]+\.[0-9]+).*@\1@")

    versionCompare "$version" ">=" "$expectedVersionMin" &&
        versionCompare "$version" "<" "$expectedVersionMax" ||
        die "Version of 'cmake-format' is '$version' but should be '[$expectedVersionMin, $expectedVersionMax)'."

    printInfo "Version: cmake-format '$version'."

    return 0
}

# Format a CMake file inplace.
function formatCMakeFile() {
    local cmakeFormatExe="$1"
    local config="$2"
    local checkOnly="$3"
    local file="$4"

    local configArgs=()
    [ -n "$config" ] && configArgs+=("-c" "$config")

    if [ "$checkOnly" = "true" ]; then
        configArgs+=("--check")
        failMsg="'$cmakeFormatExe' needs to be run on: '$file'"
        printInfo " - ✍ Checking file: '$file'"
    else
        configArgs+=("--in-place")
        failMsg="'$cmakeFormatExe' failed for: '$file'"
        printInfo " - ✍ Formatting file: '$file'"
    fi

    # Strange: only options at the end work...
    "$cmakeFormatExe" "${configArgs[@]}" "$file" &>/dev/null ||
        {
            printError "$failMsg"
            return 1
        }

    return 0
}

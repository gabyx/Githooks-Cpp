#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2015

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$DIR/../../.."
. "$ROOT_DIR/githooks/common/export-staged.sh"
. "$ROOT_DIR/githooks/common/stage-files.sh"
. "$ROOT_DIR/githooks/common/regex-cpp.sh"
. "$ROOT_DIR/githooks/common/parallel.sh"
. "$ROOT_DIR/githooks/common/log.sh"

function checkCppPrivateIncludes() {
    local file="$1"

    if echo "$file" | grep -q "^tests/"; then
        # Skip all files in root test folder.
        return 0
    fi

    printInfo " - 🔒  Checking private includes in '$file'"

    local found dir
    dir=$(dirname "$file")
    found="false"

    # Searching the `Source.cmake` file starting from  `$file`.
    while [ "$found" = "false" ]; do

        if [ -f "$dir/Sources.cmake" ]; then
            found="true"
            break
        fi

        dirN=$(dirname "$dir")        # go one directory up ...
        [ "$dir" = "$dirN" ] && break # at top of tree

        [ "$(basename "$dirN")" = "src" ] &&
            found="true" && break # reached "src" directory keep "$dir", its the best fit.

        dir="$dirN"
    done

    [ "$found" = "true" ] ||
        die "Could not find file 'Sources.cmake' above '$file'" \
            "to define library include prefix."

    # Get the library/component name from the path:
    # Merged header placement complies to be inside a source directory
    # `src/<lib-include-prefix>/Header.h`
    local error=0
    local includePrefix

    includePrefix=$(echo "$dir" | sed -E 's@(.*/)?src/(.*)@\2@') || error=1
    [ "$error" = 0 ] && [ -n "$includePrefix" ] ||
        die "Could not extract library name from '$file'." \
            "This file should be inside a directory'.../src/<lib-include-prefix>/..'" \
            "which makes it comply with the Pitchfork C++ layout" \
            "'https://github.com/vector-of-bool/pitchfork'."

    checkCppPrivateIncludesImpl "$includePrefix" "$file" || return 1
    return 0
}

function checkCppPrivateIncludesImpl() {
    # the allowed prefix for private files: e.g. `base/libA` or simply "base-libA"....
    local includePrefix="$1"
    local file="$2"

    # Check all private includes `.*-p.h` to be located in <lib-name>
    # Including private includes to other librs are an architectural design mistake.
    local regex includes errors
    regex='^\s*#\s*include\s*[<"]([^/]+/.*(details/.*|private/.*))[">].*'
    includes=$(sed -n -E "s@$regex@\1@p" "$file") ||
        die "Could not extract includes in file '$file'."

    if [ -z "$includes" ]; then
        # No private includes found.
        return 0
    fi

    local errors
    while IFS= read -r incPath; do
        echo " Include: '$incPath'"
        if ! echo "$incPath" | grep -q "^$includePrefix"; then
            errors="$errors\n   - private header '$incPath'"
        fi
    done <<<"$includes"

    if [ -n "$errors" ]; then
        printError "File '$file' must only include private files" \
            "from the same lib as '$includePrefix'" \
            "but it includes:" \
            "$errors" \
            "These are architectural design errors and need to be fixed!"
        return 1
    fi

    return 0
}

assertStagedFiles || die "Could not assert staged files."

printHeader "Running hook: Check C++: private includes ..."

export -f checkCppPrivateIncludesImpl

regex=$(getGeneralCppFileRegex) || die "Could not get C++ file regex."
parallelForFiles checkCppPrivateIncludes \
    "$STAGED_FILES" \
    "$regex" \
    "false" || die "Check C++ private includes failed."

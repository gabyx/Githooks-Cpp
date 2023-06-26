#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2015


DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$DIR/../../.."
. "$ROOT_DIR/githooks/common/export-staged.sh"
. "$ROOT_DIR/githooks/common/stage-files.sh"
. "$ROOT_DIR/githooks/common/regex-cpp.sh"
. "$ROOT_DIR/githooks/common/parallel.sh"
. "$ROOT_DIR/githooks/common/log.sh"

function checkCppNoDeadIncludes() {
    # the allowed prefix for private files: e.g. `base/libA` or simply "base-libA"....
    local file="$1"

    printInfo " - 💀  Checking no dead includes in '$file'"

    regex='^(/\*|//).*#\s*include'

    out=$(grep -hn -E "$regex" "$file")

    # shellcheck disable=SC2181
    if [ $? -eq 0 ]; then
        printError "File '$file' contains dead includes:" \
            "$(echo "$out" | sed -E 's@^@   - @g')\n  Remove them!"
        return 1
    fi
}

assertStagedFiles || die "Could not assert staged files."

printHeader "Running hook: Check C++: no dead includes ..."

export -f checkCppNoDeadIncludes

regex=$(getGeneralCppFileRegex) || die "Could not get C++ file regex."
parallelForFiles checkCppNoDeadIncludes \
    "$STAGED_FILES" \
    "$regex" \
    "false" || die "Check C++ private includes failed."

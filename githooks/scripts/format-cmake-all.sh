#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091

set -e
set -u

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
. "$DIR/../common/log.sh"
. "$DIR/../common/parallel.sh"
. "$DIR/../common/cmake-format.sh"

dryRun="true"
dir=""
excludeRegex=""
regex=$(getGeneralCMakeFileRegex)

function help() {
    printError "Usage:" \
        "  [--force]                      : Force the format." \
        "  [--exclude-regex <regex> ]     : Exclude file with this regex." \
        "  [--regex-pattern <pattern>]    : Regex pattern to include files." \
        "   --dir <path>                  : In which directory to format files."
}

function parseArgs() {
    local prev=""

    for p in "$@"; do
        if [ "$p" = "--force" ]; then
            dryRun="false"
        elif [ "$p" = "--help" ]; then
            help
            return 1
        elif [ "$p" = "--dir" ]; then
            true
        elif [ "$prev" = "--dir" ]; then
            dir="$p"
        elif [ "$p" = "--exclude-regex" ]; then
            true
        elif [ "$prev" = "--exclude-regex" ]; then
            excludeRegex="$p"
        elif [ "$p" = "--regex-pattern" ]; then
            true
        elif [ "$prev" = "--regex-pattern" ]; then
            regex="$p"
        else
            printError "! Unknown argument \`$p\`"
            help
            return 1
        fi

        prev="$p"
    done
}

parseArgs "$@"

[ -d "$dir" ] || die "Directory '$dir' does not exist."

if [ "$dryRun" = "false" ]; then
    assertCMakeFormatVersion "0.6.13" "0.6.14"
    printInfo "Formatting cmake files in dir '$dir'."
else
    printInfo "Dry-run formatting cmake files in dir '$dir'."
fi

# Format with no config -> search directory tree upwards.
parallelForDir formatCMakeFile \
    "$dir" \
    "$regex" \
    "$excludeRegex" \
    "$dryRun" \
    "cmake-format" \
    "" \
    "false" ||
    die "Formatting in '$dir' with '$regex'."

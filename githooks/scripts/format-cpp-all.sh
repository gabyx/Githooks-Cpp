#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091

set -e
set -u

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
. "$DIR/../common/log.sh"
. "$DIR/../common/parallel.sh"
. "$DIR/../common/clang-format.sh"

dryRun="true"
dir=""
excludeRegex=""
regex=$(getGeneralCppFileRegex)

function help() {
    printError "Usage:" \
        "  [--force]                      : Force the format." \
        "  [--exclude <regex> ]           : Exclude file with this regex." \
        "  [--include <pattern>]          : Regex pattern to include files." \
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
        elif [ "$p" = "--exclude" ]; then
            true
        elif [ "$prev" = "--exclude" ]; then
            excludeRegex="$p"
        elif [ "$p" = "--include" ]; then
            true
        elif [ "$prev" = "--include" ]; then
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

clangFormatExe=$(git config "githooks-cpp.clangFormat") || true
clangFormatExe="${clangFormatExe:-clang-format}"

if [ "$dryRun" = "false" ]; then
    assertClangFormatVersion "17.0.0" "18.0.0" "$clangFormatExe"
    printInfo "Formatting C++ files in dir '$dir'."
else
    printInfo "Dry-run formatting C++ files in dir '$dir'."
fi

parallelForDir formatCppFile \
    "$dir" \
    "$regex" \
    "$excludeRegex" \
    "$dryRun" \
    "$clangFormatExe" ||
    die "Formatting in '$dir' with '$regex'."

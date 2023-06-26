#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091

set -e
set -u

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
. "$DIR/../common/log.sh"
. "$DIR/../common/parallel.sh"
. "$DIR/../common/clang-format.sh"

dir="${1:-}"
excludeRegex="${2:-}"
regex="${3:-$(getGeneralCppFileRegex)}"

[ -d "$dir" ] || die "Directory '$dir' does not exist."

read -r -p "Shall we really format all files? (No, yes, dry run) [N|y|d]: " what

dryRun="false"

if [ "$what" = "d" ]; then
    what="y"
    dryRun="true"
fi

if [ "$what" = "y" ]; then

    clangFormatExe=$(git config "githooks-cppcpp.clangFormat") || true
    clangFormatExe="${clangFormatExe:-clang-format}"

    if [ "$dryRun" = "false" ]; then
        assertClangFormatVersion "12.0.0" "13.0.2" "$clangFormatExe"
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
fi

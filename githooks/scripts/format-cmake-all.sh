#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091

set -e
set -u

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
. "$DIR/../common/log.sh"
. "$DIR/../common/parallel.sh"
. "$DIR/../common/cmake-format.sh"

dir="${1:-}"
excludeRegex="${2:-}"
regex="${3:-$(getGeneralCMakeFileRegex)}"

[ -d "$dir" ] || die "Directory '$dir' does not exist."

read -r -p "Shall we really format all files? (No, yes, dry run) [N|y|d]: " what

dryRun="false"

if [ "$what" = "d" ]; then
    what="y"
    dryRun="true"
fi

if [ "$what" = "y" ]; then

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
fi

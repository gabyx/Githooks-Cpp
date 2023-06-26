#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091


DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$DIR/../../.."
. "$ROOT_DIR/githooks/common/export-staged.sh"
. "$ROOT_DIR/githooks/common/parallel.sh"
. "$ROOT_DIR/githooks/common/cmake-format.sh"
. "$ROOT_DIR/githooks/common/stage-files.sh"
. "$ROOT_DIR/githooks/common/log.sh"

assertStagedFiles || die "Could not assert staged files."

printHeader "Running hook: CMake format ..."

assertCMakeFormatVersion "0.6.13" "0.6.14"

regex=$(getGeneralCMakeFileRegex) || die "Could not get CMake file regex."
parallelForFiles formatCMakeFile \
    "$STAGED_FILES" \
    "$regex" \
    "false" \
    "cmake-format" \
    "" \
    "false" || die "CMake format failed."

#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$DIR/../../.."
. "$ROOT_DIR/githooks/common/export-staged.sh"
. "$ROOT_DIR/githooks/common/clang-format.sh"
. "$ROOT_DIR/githooks/common/stage-files.sh"
. "$ROOT_DIR/githooks/common/regex-cpp.sh"
. "$ROOT_DIR/githooks/common/parallel.sh"
. "$ROOT_DIR/githooks/common/log.sh"

assertStagedFiles || die "Could not assert staged files."

# Use clang-format executable defined in global git config
# 'githooks-cppcpp.clangFormat', this can be the clang-format
# dispatch utility to dispatch to the correct version.
clangFormatExe=$(git config "githooks-cppcpp.clangFormat") || true
clangFormatExe="${clangFormatExe:-clang-format}"

assertClangFormatVersion "17.0.0" "18.0.0" "$clangFormatExe"

printHeader "Running hook: C++ format ..."

regex=$(getGeneralCppFileRegex) || die "Could not get C++ file regex."
parallelForFiles formatCppFile \
    "$STAGED_FILES" \
    "$regex" \
    "false" \
    "$clangFormatExe" || die "C++ format failed."

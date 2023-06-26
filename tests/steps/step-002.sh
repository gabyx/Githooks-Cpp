#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2015
# Test:
#   Run cmake-format hook on staged files

set -u

. "$GH_TEST_REPO/tests/general.sh"

function finish() {
    cleanRepos
}
trap finish EXIT

initGit || die "Init failed"
installHook "$GH_TEST_REPO/githooks/pre-commit" -and -path '*/1-format/.format-cmake.sh' ||
    die "Install hook failed"

cmake-format --version || die "clang-format not available."

function setupFiles() {
    echo "set ( a  valueA valueB  )" >"CMakeLists.txt" &&
        echo "set ( a  valueA valueB  )" >"Do.cmake" || die "Could not make test sources."
}

cp "$GH_TEST_REPO/configs/.cmake-format.json" ./ &&
    setupFiles &&
    git add . || die "Could not add files."

out=$(git commit -a -m "Formatting files." 2>&1)
# shellcheck disable=SC2181
if [ $? -ne 0 ] ||
    ! echo "$out" | grep -qi "formatting.*CMakeLists.txt" ||
    ! echo "$out" | grep -qi "formatting.*Do.cmake"; then
    echo "Expected to have formatted all files."
    echo "$out"
    exit 1
fi

if git diff --quiet; then
    echo "Expected repository to be dirty. Formatted files not checked in."
    git status
    exit 1
fi

if ! git diff --quiet --cached; then
    echo "Formatted files are staged but should not."
    git status
    exit 1
fi

if ! grep -q "set(a valueA valueB)" "CMakeLists.txt" ||
    ! grep -q "set(a valueA valueB)" "Do.cmake"; then
    echo "Expected files to be formatted."
    exit 1
fi

#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2015
# Test:
#   Run clang-format hook on staged files

set -u

. "$GH_TEST_REPO/tests/general.sh"

function finish() {
    cleanRepos
}
trap finish EXIT

initGit || die "Init failed"
installHook "$GH_TEST_REPO/githooks/pre-commit" -and -path '*/1-format/.format-cpp.sh' ||
    die "Install hook failed"

clang-format --version || die "clang-format not available."

function setupFiles() {
    echo "int a  = 3;" >"A1.cpp" &&
        echo "int a  = 3  ;" >"A2.h" &&
        echo "int a  = 3  ;" >"A3.cxx" &&
        echo "int a  = 3  ; " >"A4.inc" &&
        echo "int a  = 3 ;" >"A5.hpp" &&
        echo "int a  = 3  ;" >"A6.mm"
}

echo "BasedOnStyle: Google" >".clang-format" && setupFiles ||
    die "Could not make test sources."

git add . || die "Could not add files."

out=$(git commit -a -m "Formatting files." 2>&1)
# shellcheck disable=SC2181
if [ $? -ne 0 ] ||
    ! echo "$out" | grep -qi "formatting.*A1.cpp" ||
    ! echo "$out" | grep -qi "formatting.*A2.h" ||
    ! echo "$out" | grep -qi "formatting.*A3.cxx" ||
    ! echo "$out" | grep -qi "formatting.*A4.inc" ||
    ! echo "$out" | grep -qi "formatting.*A5.hpp" ||
    ! echo "$out" | grep -qi "formatting.*A6.mm"; then
    echo "Expected to have formatted all files."
    echo "$out"
    exit 1
fi

if ! git diff --quiet; then
    echo "Expected repository to be not dirty, formatted files are staged."
    git status
    exit 1
fi

if ! git diff --quiet --cached; then
    echo "Formatted files are staged but should not."
    git status
    exit 1
fi

setupFiles || die "Could not setup files again."

if [ "$(git status --short | grep -c 'A.*')" != "6" ]; then
    echo "Expected repository to be dirty, formatting did not work."
    git status
    exit 1
fi

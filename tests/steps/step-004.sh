#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2015
# Test:
#   Run check-cpp-private-includes hook.

set -u

. "$GH_TEST_REPO/tests/general.sh"

function finish() {
    cleanRepos
}
trap finish EXIT

initGit || die "Init failed"
installHook "$GH_TEST_REPO/githooks/pre-commit" -and -path '*/2-check/.check-no-dead-includes-cpp.sh' ||
    die "Install hook failed"

function setupFiles() {
    echo -e '/** #include "D" */' >A.cpp
    echo -e '//* #include "D" */' >B.cpp
    echo -e '#include "D" /* asd */' >C.cpp
}

cp "$GH_TEST_REPO/configs/.cmake-format.json" ./ &&
    setupFiles &&
    git add . || die "Could not add files."

out=$(git commit -a -m "Checking files." 2>&1)
# shellcheck disable=SC2181
if [ $? -eq 0 ] ||
    ! echo "$out" | grep -qi "A.cpp' contains dead" ||
    ! echo "$out" | grep -qi "B.cpp' contains dead" ||
    echo "$out" | grep -qi "C.cpp' contains dead"; then
    echo "Expected to error on dead includes."
    echo "$out"
    exit 1
fi

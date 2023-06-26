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
installHook "$GH_TEST_REPO/githooks/pre-commit" -and -path '*/2-check/.check-private-includes-cpp.sh' ||
    die "Install hook failed"

function setupFiles() {
    mkdir -p src/libA/math/details src/base/libA ||
        die "Could not made directories."

    echo -e '#include <libA/private/A.h>\n' \
        '\n# include  <libB/math/private/BB.h>' \
        '\n# include "libB/math/private/CC.inl"' \
        >src/libA/A1.cpp

    echo -e '#include <libA/private/A.h>' \
        '\n# include "libC/math/details/DD.inl"' \
        >src/libA/math/A2.cpp

    echo -e '#include <libA/private/A.h>' \
        '\n#include <libC/details/EE.h>' \
        '\n# include  <libD/math/FF.h>' \
        '\n# include "libD/math/GG-asd.inl"' \
        >src/libA/math/details/A3.cpp

    touch src/base/libA/Sources.cmake # marking a library directory and $(base/libA) as the library include prefix.
    echo -e '#include <base/libA/private/A.h>' \
        '\n# include  <base/libE/math/private/HH.h>' \
        '\n# include "base/libE/math/details/II.inl"' \
        >src/base/libA/A1.cpp
}

cp "$GH_TEST_REPO/configs/.cmake-format.json" ./ &&
    setupFiles &&
    git add . || die "Could not add files."

out=$(git commit -a -m "Checking files." 2>&1)
# shellcheck disable=SC2181
if [ $? -eq 0 ] ||
    ! echo "$out" | grep -qi "/BB.h" ||
    ! echo "$out" | grep -qi "/CC.inl" ||
    ! echo "$out" | grep -qi "/DD.inl" ||
    ! echo "$out" | grep -qi "/EE.h" ||
    echo "$out" | grep -qi "/FF" ||
    echo "$out" | grep -qi "/GG" ||
    ! echo "$out" | grep -qi "/HH.h" ||
    ! echo "$out" | grep -qi "/II.inl"; then
    echo "Expected to error on private includes to other libs."
    echo "$out"
    exit 1
fi

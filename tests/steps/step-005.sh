#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2015
# Test:
#   Run clang-format hook on staged GLSL files

set -u

. "$GH_TEST_REPO/tests/general.sh"

function finish() {
    cleanRepos
}
trap finish EXIT

initGit || die "Init failed"
installHook "$GH_TEST_REPO/githooks/pre-commit" -and -path '*/1-format/.format-glsl.sh' ||
    die "Install hook failed"

clang-format --version || die "clang-format not available."

function setupFiles() {
    {
        echo "struct SVertexOutput{"
        echo " vec4 position; //!< Fragment position in clip space"
        echo "  vec3 view;     //!< View vector"
        echo "  vec2 uv;       //!< Texture coordinate"
        echo "}"
    } >"A1.glsl"
}

echo "BasedOnStyle: Google" >".clang-format" && setupFiles ||
    die "Could not make test sources."

git add . || die "Could not add files."

out=$(git commit -a -m "Formatting files." 2>&1)
# shellcheck disable=SC2181
if [ $? -ne 0 ] ||
    ! echo "$out" | grep -qi "formatting.*A1.glsl"; then
    echo "Expected to have formatted all files."
    echo "$out"
    exit 1
fi

if ! git diff --quiet; then
    echo "Expected repository to be not dirty, formatted files are amended."
    git status
    exit 1
fi

if ! git diff --quiet --cached; then
    echo "Formatted files are staged but should not (should been amended and checked in)."
    git status
    exit 1
fi

setupFiles || die "Could not setup files again."

if [ "$(git status --short | grep -c 'A.*')" != "1" ]; then
    echo "Expected repository to be dirty, formatting did not work."
    git status
    exit 1
fi

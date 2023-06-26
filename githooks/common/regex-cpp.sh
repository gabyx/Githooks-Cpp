#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2015


# Get the general cpp file regex.
function getGeneralCppFileRegex() {
    echo '.*\.(h|hpp|cpp|inc|cxx|c|mm|mpp)$'
}

# Get the general GLSL file regex.
function getGeneralGLSLFileRegex() {
    echo '.*\.(glsl)$'
}

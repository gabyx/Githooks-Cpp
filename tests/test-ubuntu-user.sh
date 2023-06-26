#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091

ROOT_DIR=$(git rev-parse --show-toplevel)
. "$ROOT_DIR/tests/general.sh"

cat <<EOF | docker build --force-rm -t general-githooks-cpp:ubuntu-user-base - || die "Could not build conatainer."
FROM ubuntu:jammy
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y git llvm-12 clang-12 lldb-12 clang-format-12 clang-tidy-12 && \
    update-alternatives --install /usr/bin/clang clang /usr/bin/clang-12 100 && \
    update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-12 100 && \
    update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-12 100 && \
    update-alternatives --install /usr/bin/clang-tidy clang-tidy /usr/bin/clang-tidy-12 100

RUN apt-get install -y python pip
RUN pip3 install cmakelang
EOF

# shellcheck disable=SC2016,SC1004
export ADDITIONAL_PRE_INSTALL_STEPS='
RUN useradd \
    -m --shell /bin/bash \
    -G sudo "test" && \
    passwd -d "test" && \
    chown -R "test:test" /home
USER test
RUN mkdir -p /home/test/tmp
ENV GH_TEST_TMP=/home/test/tmp
ENV GH_TEST_REPO=/home/test/general-githooks-cpp
'

"$ROOT_DIR/tests/exec-tests.sh" 'ubuntu-user' "$@"

# Test with parallel
export ADDITIONAL_PRE_INSTALL_STEPS="
RUN apt-get install -y parallel
$ADDITIONAL_PRE_INSTALL_STEPS
"

"$ROOT_DIR/tests/exec-tests.sh" 'ubuntu-user' "$@"

docker rmi "general-githooks-cpp:ubuntu-user-base-base"

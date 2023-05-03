#!/bin/bash

# Hints:
# http://boost.2283326.n4.nabble.com/how-to-build-boost-with-bzip2-in-non-standard-location-td2661155.html
# http://www.gentoo.org/proj/en/base/amd64/howtos/?part=1&chap=3
# http://www.boost.org/doc/libs/1_55_0/doc/html/bbv2/reference.html

# Hints for OSX:
# http://stackoverflow.com/questions/20108407/how-do-i-compile-boost-for-os-x-64b-platforms-with-stdlibc

set -x -e
set -o pipefail

INCLUDE_PATH="${PREFIX}/include"
LIBRARY_PATH="${PREFIX}/lib"

# Always build PIC code for enable static linking into other shared libraries
CXXFLAGS="${CXXFLAGS} -fPIC"
# Ensure we always find the correct Python headers (needed for PyPy builds)
CXXFLAGS="${CXXFLAGS} -isystem $(python -c 'import sysconfig; print(sysconfig.get_config_var("INCLUDEPY"))')"

if [[ "${target_platform}" == osx* ]]; then
    TOOLSET=clang
elif [[ "${target_platform}" == linux* ]]; then
    TOOLSET=gcc
fi

# http://www.boost.org/build/doc/html/bbv2/tasks/crosscompile.html
cat <<EOF > ${SRC_DIR}/tools/build/src/site-config.jam
using ${TOOLSET} : : ${CXX} ;
EOF

LINKFLAGS="${LINKFLAGS} -L${LIBRARY_PATH}"

ADDRESS_MODEL="${ARCH}"
ARCHITECTURE=x86
ABI="sysv"
if [ "${ADDRESS_MODEL}" == "aarch64" ] || [ "${ADDRESS_MODEL}" == "arm64" ]; then
    ADDRESS_MODEL=64
    ARCHITECTURE=arm
    ABI="aapcs"
elif [ "${ADDRESS_MODEL}" == "ppc64le" ]; then
    ADDRESS_MODEL=64
    ARCHITECTURE=power
fi

if [[ "$target_platform" == osx-* ]]; then
    BINARY_FORMAT="mach-o"
elif [[ "$target_platform" == linux-* ]]; then
    BINARY_FORMAT="elf"
fi

# clean up directory from build.sh and reuse b2 built there
rm -rf temp_prefix

./b2 -q \
    variant=release \
    address-model="${ADDRESS_MODEL}" \
    architecture="${ARCHITECTURE}" \
    binary-format="${BINARY_FORMAT}" \
    abi="${ABI}" \
    debug-symbols=off \
    threading=multi \
    runtime-link=shared \
    link=static,shared \
    toolset=${TOOLSET} \
    python="${PY_VER}" \
    include="${INCLUDE_PATH}" \
    cxxflags="${CXXFLAGS}" \
    linkflags="${LINKFLAGS}" \
    --layout=system \
    --with-python \
    -j"${CPU_COUNT}" \
    install 2>&1 | tee b2.log

#!/bin/bash
set -ex

# work-around for https://github.com/bfgroup/b2/issues/405
echo "using python" > user-config.jam
echo ": $PY_VER" >> user-config.jam
echo ": $PYTHON" >> user-config.jam
echo ": $PREFIX/include/python$PY_VER" >> user-config.jam
echo ": $PREFIX/lib" >> user-config.jam
echo ";" >> user-config.jam
# see https://www.boost.org/build/doc/html/bbv2/overview/configuration.html
export BOOST_BUILD_PATH=$SRC_DIR

# Hints:
# http://boost.2283326.n4.nabble.com/how-to-build-boost-with-bzip2-in-non-standard-location-td2661155.html
# http://www.gentoo.org/proj/en/base/amd64/howtos/?part=1&chap=3
# http://www.boost.org/doc/libs/1_55_0/doc/html/bbv2/reference.html

# Hints for OSX:
# http://stackoverflow.com/questions/20108407/how-do-i-compile-boost-for-os-x-64b-platforms-with-stdlibc

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

LINKFLAGS="-L${LIBRARY_PATH}"

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

# $PREFIX/lib/cmake/boost_headers-$PKG_VERSION/boost_headers-config.cmake has
# already been packaged (including the python headers!) into libboost-headers,
# however the installation below will overwrite it with another (smaller) set
# of metadata, causing a potentially corrupted package. Save the file in
# question and restore it below.
mkdir -p $SRC_DIR/cf_cmake
mv $PREFIX/lib/cmake/boost_headers-$PKG_VERSION/boost_headers-config.cmake $SRC_DIR/cf_cmake/

mkdir build-py

./b2 -q \
    --build-dir=build-py \
    variant=release \
    address-model="${ADDRESS_MODEL}" \
    architecture="${ARCHITECTURE}" \
    binary-format="${BINARY_FORMAT}" \
    abi="${ABI}" \
    debug-symbols=off \
    threading=multi \
    runtime-link=shared \
    link=shared \
    toolset=${TOOLSET} \
    python="${PY_VER}" \
    include="${INCLUDE_PATH}" \
    cxxflags="${CXXFLAGS}" \
    linkflags="${LINKFLAGS}" \
    --layout=system \
    --with-python \
    -j"${CPU_COUNT}" \
    install 2>&1 | tee b2.log

# clean up between builds for different python versions/implementations
rm -rf build-py

# see comment above; move, don't copy (avoids collisions between runs)
mv $SRC_DIR/cf_cmake/boost_headers-config.cmake $PREFIX/lib/cmake/boost_headers-$PKG_VERSION/

# remove CMake metadata from libboost-python; save it for libboost-python-dev
# needs to be done separately per python version & implementation
mkdir -p $SRC_DIR/cf_${PY_VER}_${python_impl}_cmake
mv $PREFIX/lib/cmake/boost_python-$PKG_VERSION $SRC_DIR/cf_${PY_VER}_${python_impl}_cmake/
mv $PREFIX/lib/cmake/boost_numpy-$PKG_VERSION $SRC_DIR/cf_${PY_VER}_${python_impl}_cmake/

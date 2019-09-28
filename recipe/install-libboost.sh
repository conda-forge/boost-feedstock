#!/bin/bash

set -x -e

./b2 -q -d+2 \
     install | tee b2.install-libboost.log 2>&1

# Remove Python headers as we don't build Boost.Python.
rm "${PREFIX}/include/boost/python.hpp"
rm -r "${PREFIX}/include/boost/python"

mkdir -p ${PREFIX}/bin
cp ./b2 "${PREFIX}/bin/b2" || exit 1
pushd "${PREFIX}/bin"
    ln -s b2 bjam || exit 1
popd

pushd tools/build/src
  for _dir in build kernel options tools util; do
    mkdir -p "${PREFIX}/share/boost-build/src/${_dir}"
    cp -rf ${_dir}/* "${PREFIX}/share/boost-build/src/${_dir}/"
  done
  cp -f build-system.jam "${PREFIX}/share/boost-build/src/"
popd
pushd tools/build
  cp -f *.jam "${PREFIX}/share/boost-build"
popd

# We have patched build-system.jam to use this file when
# the CONDA_PREFIX environment variable is set.
mkdir -p "${PREFIX}/etc"
cp ${SRC_DIR}/tools/build/src/site-config.jam "${PREFIX}/etc"

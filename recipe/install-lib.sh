#!/bin/bash
set -ex

# for libboost-headers, only the headers
cp -R temp_prefix/include/* $PREFIX/include/

# everything else
if [[ "$PKG_NAME" == "boost-cpp" ]]; then
    cp -R temp_prefix/lib/* $PREFIX/lib
fi

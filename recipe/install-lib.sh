#!/bin/bash
set -ex

if [[ "$PKG_NAME" == "libboost-headers" ]]; then
    # for libboost-headers, only the headers;
    # since we have no host dependencies, the folder $PREFIX/include does not exist yet,
    # so the syntax for `copy` works differently than below (where $PREFIX/lib exists).
    cp -R temp_prefix/include $PREFIX/include
elif [[ "$PKG_NAME" == "libboost" ]]; then
    # only the libraries (don't copy CMake metadata)
    cp -R temp_prefix/lib/libboost*${SHLIB_EXT}* $PREFIX/lib
    cp -R temp_prefix/lib/libboost*.a $PREFIX/lib
else
    # everything else
    cp -R temp_prefix/lib/* $PREFIX/lib
fi

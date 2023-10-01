#!/bin/bash
set -ex

if [[ "$PKG_NAME" == "libboost-headers" ]]; then
    # for libboost-headers, only the headers;
    cp -R temp_prefix/include/. $PREFIX/include
elif [[ "$PKG_NAME" == "libboost" ]]; then
    # only the libraries (don't copy CMake metadata)
    cp -R temp_prefix/lib/libboost*${SHLIB_EXT}* $PREFIX/lib
    cp -R temp_prefix/lib/libboost*.a $PREFIX/lib
else
    # everything else
    if [[ "$target_platform" == "osx-arm64" ]]; then
        # osx-arm64 is special, because we need to generate signatures
        # for the libraries, which only happens on first installation;
        # if we overwrite the libs with the unsigned artefacts, conda
        # gets confused/unhappy, see #178;
        # therefore, copy already installed (=signed) libs into temp_prefix
        # before installation (=copy to $PREFIX), overwriting the unsigned
        # ones, ensuring that there's only one bit-for-bit variant per lib.
        cp $PREFIX/lib/libboost*.dylib temp_prefix/lib
    fi
    cp -R temp_prefix/lib/. $PREFIX/lib
fi

#!/bin/bash
set -ex

# see build-py.sh
mv $SRC_DIR/cf_${PY_VER}_cmake/* $PREFIX/lib/cmake

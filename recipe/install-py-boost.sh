#!/bin/bash

set -x -e

# remove any old builds of the python target
./b2 -q -d+2 --with-python --clean

./b2 -q -d+2 \
     python=${PY_VER} \
     -j${CPU_COUNT} \
     --with-python \
    --reconfigure \
     cxxflags="${CXXFLAGS} -Wno-deprecated-declarations" \
     clean

./b2 -q -d+2 \
     python=${PY_VER} \
     -j${CPU_COUNT} \
     --with-python \
    --reconfigure \
     cxxflags="${CXXFLAGS} -Wno-deprecated-declarations" \
     install | tee b2.install-py-${PY_VER}.log 2>&1

# This no longer works for Python 2.
# boost.python, when driven via bjam always links to boost_python
# instead of boost_python3. It also does not add any specified
# --python-buildid; ping @stefanseefeld
# pushd "${PREFIX}/lib"
#   ln -s libboost_python${PY_VER//./}.a libboost_python.a
#   ln -s libboost_numpy${PY_VER//./}.a libboost_numpy.a
#   if [[ ${HOST} =~ .*darwin.* ]]; then
#     ln -s libboost_python${PY_VER//./}.dylib libboost_python.dylib
#     ln -s libboost_numpy${PY_VER//./}.dylib libboost_numpy.dylib
#   else
#     ln -s libboost_python${PY_VER//./}.so libboost_python.so
#     ln -s libboost_numpy${PY_VER//./}.so libboost_numpy.so
#   fi
# popd

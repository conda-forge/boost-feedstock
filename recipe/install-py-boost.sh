#!/bin/bash

set -x -e

# remove any old builds of the python target
./b2 -q -d+2 --with-python --clean

for PY_VER2 in 2.7 2.6 3.7; do
    ./b2 -q -d+2 \
        --with-python \
        python=${PY_VER} \
        --reconfigure \
        -j${CPU_COUNT} \
        cxxflags="${CXXFLAGS} -Wno-deprecated-declarations" \
        clean
done

./b2 -q -d+2 \
     --with-python \
     python=${PY_VER} \
    --reconfigure \
     -j${CPU_COUNT} \
     cxxflags="${CXXFLAGS} -Wno-deprecated-declarations" \
     install | tee b2.install-py-${PY_VER}.log 2>&1

# boost.python, when driven via bjam always links to boost_python
# instead of boost_python3. It also does not add any specified
# --python-buildid; ping @stefanseefeld
pushd "${PREFIX}/lib"
  ln -s libboost_python${PY_VER//./}.a libboost_python.a
  ln -s libboost_numpy${PY_VER//./}.a libboost_numpy.a
  if [[ ${target_platform} == osx-64 ]]; then
    ln -s libboost_python${PY_VER//./}.dylib libboost_python.dylib
    ln -s libboost_numpy${PY_VER//./}.dylib libboost_numpy.dylib
  else
    ln -s libboost_python${PY_VER//./}.so libboost_python.so
    ln -s libboost_numpy${PY_VER//./}.so libboost_numpy.so
  fi
popd

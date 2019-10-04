#!/usr/bin/env bash

source ~/gd.cio/bin/rotatelogs.sh

RECIPE_DIR=$(dirname ${BASH_SOURCE[0]})
if [[ ${RECIPE_DIR} == . ]]; then
  RECIPE_DIR=${PWD}
fi
echo $RECIPE_DIR
if [[ $(uname) =~ .*inux.* ]]; then
  SUBDIR=linux-64
elif [[ $(uname) == Darwin ]]; then
  SUBDIR=osx-64
fi

TMPBUILDS=/tmp/boost-RANDOM

run_tests() {
  conda deactivate
  local _TESTDIR="$1"; shift
  local _BJAM="$1"; shift
  local _PYTHON="$1"; shift

  [[ -d ${_TESTDIR} ]] && rm -rf ${_TESTDIR}
  mkdir -p ${_TESTDIR}

  pushd ${_TESTDIR}

  if [[ ! -d /opt/src/boostorg_python/example/tutorial ]]; then
    echo "ERROR :: opt/src/boostorg_python/example/tutorial does not exist"
    return -3
  fi

  if [[ ! -f ${_BJAM} ]]; then
    echo "ERROR :: _BJAM ${_BJAM} does not exist"
    return -4
  fi

  if [[ ! -f ${_PYTHON} ]]; then
    echo "ERROR :: _PYTHON ${_PYTHON} does not exist"
    return -5
  fi

  pushd /opt/src/boostorg_python/example/tutorial
  git clean -dxf .
  # Not sure what to do about this one. We do not want to force people to do this from their prompts, I do not
  # think, but we also do not want to bake the value in either.
  export CONDA_BUILD_SYSROOT=/opt/MacOSX10.10.sdk
  export CONDA_BUILD=1
  ${_BJAM} -q -d+2 --debug --debug-configuration /opt/src/boostorg_python/example/tutorial
  if [[ $? != 0 ]]; then
    echo "ERROR :: boost-python example/tutorial build failed with $1"
    exit -6
  fi
  ${_PYTHON} -c 'from __future__ import print_function; import hello_ext; print(hello_ext.greet())'
  if [[ $? != 0 ]]; then
    echo "ERROR :: boost-python example/tutorial import failed with $1"
    exit -7
  fi
  popd
  conda activate
}

# Exterior build => put into a general script for each type of build?
if [[ 0 == 0 ]]; then
  mkdir ${TMPBUILDS} || true
  pushd ${TMPBUILDS}
    if [[ $(uname) =~ .*inux.* ]]; then
      OTHER_BUILD_DIR=${RECIPE_DIR}/standard-build
      TMPBUILD=${TMPBUILDS}/standard-build
      mkdir -p ${TMPBUILD} || true
      pushd ${TMPBUILD}
        wget -c https://dl.bintray.com/boostorg/release/1.71.0/source/boost_1_71_0.tar.bz2
        [[ -d boost_1_71_0 ]] && rm -rf boost_1_71_0
        tar -xf boost_1_71_0.tar.bz2
        pushd boost_1_71_0
        git init
        git add .
        git commit -m "Initial commit"
        set -x
          _INSTALL=${PWD}/install
          ls /tmp/boost-RANDOM/standard-build/boost_1_71_0/tools/build/src/tools/python.jam
          pwd
          patch -p2 < /opt/r/a/boost-feedstock/recipe/0002-boost.python-fix-python-lib-config-abiflags.patch
          ./bootstrap.sh --with-python=/usr/bin/python3 2>&1 | tee bootstrap.log
          ./b2 install --prefix=${_INSTALL} 2>&1 | tee install.log
          mkdir -p ${_INSTALL}/bin
          cp ./b2 "${_INSTALL}/bin/b2" || exit 1
          pushd "${_INSTALL}/bin"
            ln -s b2 bjam || exit 1
          popd

          pushd tools/build/src
            for _dir in build kernel options tools util; do
              mkdir -p "${_INSTALL}/share/boost-build/src/${_dir}"
              cp -rf ${_dir}/* "${_INSTALL}/share/boost-build/src/${_dir}/"
            done
            cp -f build-system.jam "${_INSTALL}/share/boost-build/src/"
          popd
          pushd tools/build
            cp -f *.jam "${_INSTALL}/share/boost-build"
          popd

          OTHER_BUILD_PYTHON=/usr/bin/python
          OTHER_BUILD_BJAM=${PWD}/install/bin/bjam
        popd
      popd
    elif [[ $(uname) =~ .*inuxNO.* ]]; then
      # We do not build out of OTHER_BUILD_DIR, it's a backup of only the most important stuff and processed separately.
      # This block must set OTHER_BUILD_DIR (full path), TMPBUILD (full path), 
      OTHER_BUILD_DIR=${RECIPE_DIR}/archlinux
      TMPBUILD=${TMPBUILDS}/archlinux
      mkdir -p ${TMPBUILD} || true
      pushd ${TMPBUILD}
        cp /opt/src/archlinux.packages/boost/trunk/PKGBUILD .
        makepkg -sLf
      popd
      OTHER_BUILD_PYTHON=$(which python)
      OTHER_BUILD_BJAM=$(which bjam)
    elif [[ $(uname) == Darwin ]]; then
      OTHER_BUILDSYS_PREFIX=${HOME}/brew
      [[ -d ${OTHER_BUILDSYS_PREFIX}/bin/brew ]] || OTHER_BUILDSYS_PREFIX=${HOME}/homebrew
      [[ -d ${OTHER_BUILDSYS_PREFIX}/bin/brew ]] || OTHER_BUILDSYS_PREFIX=/usr/local
      if [[ -d ${OTHER_BUILDSYS_PREFIX}/bin/brew ]]; then
        echo "ERROR :: Failed to locate brew executable in some sensible prefixes (${HOME}/brew, ${HOME}/homebrew, /usr/local"
        exit -7
      fi
      USING_TOOLSET_CONDA=no
      declare -a USING_TOOLSET=()
      if [[ ${USING_TOOLSET_CONDA} == yes ]]; then
        _SUFFIX=.ts-conda
        CONDA_ACTIVATED=no
        if [[ ! -d /opt/Xcode-avoidance ]]; then
          conda create -y -p /opt/Xcode-avoidance clangxx_osx-64
        fi
        conda activate --stack /opt/Xcode-avoidance && CONDA_ACTIVATED=yes
        # USING_TOOLSET+=(--cc)
        # USING_TOOLSET+=($(basename ${CXX//-g++/}))
        # USING_TOOLSET+=(--cc=$(basename ${CC%%-clang}))
        # USING_TOOLSET+=(--cc=$(basename ${CC%%-gcc}))
        USING_TOOLSET+=(--cc=$(basename ${CC}))
        echo "${USING_TOOLSET[@]}"
      else
        USING_TOOLSET+=(--cc=llvm_clang)
        _SUFFIX=.ts-xcode
      fi
      TMPBUILD=${TMPBUILDS}/homebrew${_SUFFIX}
      mkdir -p ${TMPBUILD} || true
      pushd ${TMPBUILD}
        OTHER_BUILD_DIR=${RECIPE_DIR}/homebrew${_SUFFIX}
        set -x
        for _PKG in boost-python boost-python; do
          ${OTHER_BUILDSYS_PREFIX}/bin/brew uninstall -f --ignore-dependencies ${_PKG} || true
        done
        for _PKG in boost boost-python; do
          TMPDIR=${TMPDIR}/boost.build \
          HOMEBREW_NO_AUTO_UPDATE=1 \
            ${OTHER_BUILDSYS_PREFIX}/bin/brew install "${USING_TOOLSET[@]}" --build-from-source \
              --keep-tmp --debug \
              ${_PKG} 2>&1 | tee ${_PKG}.log
        done
        OTHER_BUILD_PYTHON=${OTHER_BUILDSYS_PREFIX}/bin/python
        OTHER_BUILD_BJAM=${OTHER_BUILDSYS_PREFIX}/bin/bjam
        set +x
      popd
      if [[ ${CONDA_ACTIVATED} == yes ]]; then
        conda deactivate
      fi
    fi
  popd
  _TESTDIR=/tmp/test-$$
  run_tests ${_TESTDIR} ${OTHER_BUILD_BJAM} ${OTHER_BUILD_PYTHON}
  pushd ${_TESTDIR}
    cp *.log ${OTHER_BUILD_DIR}
  popd
  cp ${TMPBUILD}/*.log ${OTHER_BUILD_DIR}

  exit 1

  mkdir ${OTHER_BUILD_DIR} || true
  pushd ${OTHER_BUILD_DIR}
    rotatelogs *.log
    cp *.log *.tar.xz .
  popd
fi

# Now the conda-build build
pushd ${RECIPE_DIR}/../../
  [[ -d ${RECIPE_DIR}/conda-build.logs/${SUBDIR} ]] || mkdir -p ${RECIPE_DIR}/conda-build.logs/${SUBDIR}
  rotatelogs ${RECIPE_DIR}/conda-build.logs/${SUBDIR}/boost-feedstockf.log
  [[ -d /opt/b/boost-feedstock ]] && rm -rf /opt/b/boost-feedstock
  bash ~/gd.cio/bin/cblfc boost-feedstock
  [[ -f /opt/logs/${SUBDIR}/boost-feedstockf.log ]] && cp /opt/logs/${SUBDIR}/boost-feedstockf.log ${RECIPE_DIR}/conda-build.logs/${SUBDIR}/boost-feedstockf.log
  _WORK_MOVED=$(find /opt/b/boost-feedstock/ -name "work_moved*")
  for _WORK in ${_WORK_MOVED}; do
    pushd ${_WORK}
      cp -rf *.log ${RECIPE_DIR}/conda-build.logs/
    popd
  done
  [[ -d /opt/b/boost-feedstock/work ]] && cp -rf /opt/b/boost-feedstock/work/*.log ${RECIPE_DIR}/conda-build.logs/
popd

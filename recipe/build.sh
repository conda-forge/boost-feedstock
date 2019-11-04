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

declare -a _TP_OPTS=()
if [[ ${target_platform} == osx-64 ]]; then
  _TP_OPTS+=(target-os=darwin)
  _TP_OPTS+=(binary-format=mach-o)
  _TP_OPTS+=(abi=sysv)
  _TP_OPTS+=(threading=multi)
  # See this comment in tools/build/src/tools/darwin.jam
  # "# - The archive builder (libtool is the default as creating
  #  #   archives in darwin is complicated."
  ARCHIVER=${LIBTOOL}
  # Maybe clang?
  TOOLSET_REAL=darwin
  TOOLSET_VERSION=4.0.1
else
  TOOLSET_REAL=gcc
  TOOLSET_VERSION=7.3.0
  ARCHIVER=${AR}
fi

# cross-cxx toolset is available for cross-compiling, but does not appear to work
export BUILD_CXX=${CXX}
export BUILD_CXXFLAGS=${CXXFLAGS}
export BUILD_LDFLAGS=${LDFLAGS}
TOOLSET=cxx

# http://www.boost.org/build/doc/html/bbv2/tasks/crosscompile.html
cat <<EOF > ${SRC_DIR}/tools/build/src/site-config.jam
using ${TOOLSET} : : ${CXX} ;
EOF

LINKFLAGS="${LINKFLAGS} -L${LIBRARY_PATH}"

./bootstrap.sh \
    --prefix="${PREFIX}" \
    --with-icu="${PREFIX}" \
    --with-toolset=${TOOLSET}  \
    --without-libraries=python  \
    2>&1 | tee bootstrap.log

# Boost's build system is not fun to work with.
if [[ ${TOOLSET} == cxx ]]; then
  TOOLSET_NEW=${TOOLSET_REAL}
  sed -i.bak "s,cxx,${TOOLSET_NEW},g" project-config.jam
  sed -i.bak "s,cxx,${TOOLSET_NEW},g" tools/build/src/site-config.jam
  TOOLSET=${TOOLSET_NEW}
fi

# Archlinux emits this into project-config.jam (well, for python2.7 initially
# alongside the build of all the rest, then this is sedded into this file and
# a build of boost-python (into a different dir) is performed.
# if ! [ python.configured ]
# {
#    using python : 3.7 : "/usr" : /usr/include/python3.7m ;
# }


for _SCJ in site-config.jam tools/build/src/site-config.jam; do
  cat << EOF > ${_SCJ}
  using ${TOOLSET} : ${TOOLSET_VERSION} : $(basename ${CXX})
              : # options
                  <archiver>$(basename ${ARCHIVER})
                  <asmflags>${CFLAGS}
                  <cflags>${CFLAGS}
                  <cxxflags>${CXXFLAGS}
                  <linkflags>${LDFLAGS}
                  <ranlib>$(basename ${RANLIB})
              ;
EOF
done

declare -a _ALL_OPTS=()
_GENERIC_OPTS+=(-q)
_GENERIC_OPTS+=(-d+2)
_GENERIC_OPTS+=(variant=release)
_GENERIC_OPTS+=(address-model="${ARCH}")
_GENERIC_OPTS+=(architecture=x86)
_GENERIC_OPTS+=(debug-symbols=off)
# TODO :: Put the single threaded libraries into a separate library if we want this:
#         Some research (as of 1.71.0):
#         1. Homebrew provide single threaded too (threading=multi,single)
#            (https://github.com/Homebrew/homebrew-core/blob/master/Formula/boost.rb,
#             https://github.com/Homebrew/homebrew-core/blob/master/Formula/boost-python3.rb)
#             .. they do this for boost-python3's test; we do not (not do we want to):
#             https://github.com/Homebrew/homebrew-core/blob/e7c8239a8a7c9b4501c4a18a4028cae82e254984/Formula/boost-python3.rb#L90-L95
#             .. and this for boost-python (2)'s test:
#             https://github.com/Homebrew/homebrew-core/blob/e7c8239a8a7c9b4501c4a18a4028cae82e254984/Formula/boost-python.rb#L61-L67
#         2. Achlinux provide multi threaded-only
#            (https://git.archlinux.org/svntogit/packages.git/tree/trunk/PKGBUILD?h=packages/boost)
#         3. RStudio builds boost (1.69.0) with only threading=multi too
#            (https://github.com/rstudio/rstudio/blob/master/dependencies/common/install-boost)
# _GENERIC_OPTS+=(threading=multi,single)
_GENERIC_OPTS+=(threading=multi)
_GENERIC_OPTS+=(runtime-link=shared)
_GENERIC_OPTS+=(link=static,shared)
_GENERIC_OPTS+=(include="${INCLUDE_PATH}")
_GENERIC_OPTS+=(cxxflags="${CXXFLAGS} -Wno-deprecated-declarations")
_GENERIC_OPTS+=(linkflags="${LINKFLAGS}")
_GENERIC_OPTS+=(--layout=system)
_GENERIC_OPTS+=(--without-python)
_GENERIC_OPTS+=(--keep-going=false)

# There is no configure target, however configuration does happen and
# can fail. Passing in a target that does not exist allows us to exit
# out very quickly when things go awry.

echo "Information :: Calling b2 with a fake target to catch early failures"

./b2 "${_GENERIC_OPTS[@]}" \
     "${_TP_OPTS[@]}" \
     -j"${CPU_COUNT}" \
     target_does_not_exist > b2.configure.log 2>&1 || true

for _MSG in error: warning:; do
  if grep -q "^${_MSG}" b2.configure.log; then
    echo -e "\n\n***** $(echo ${_MSG::${#_MSG} - 1} | tr 'a-z' 'A-Z') *****"
    echo -e "\nThe following ${_MSG::${#_MSG} - 1} were found during the configuration stage of b2:\n"
    grep "^${_MSG}" b2.configure.log -A2 || true
    echo -e "\n\n***** $(echo ${_MSG::${#_MSG} - 1} | tr 'a-z' 'A-Z') *****\n"
    if [[ "${_MSG}" == "error:" ]]; then
      echo -e ".. stopping build.\n"
      exit 1
    else
      echo ".. ingoring."
    fi
  fi
done

echo "Information :: Calling b2 with no target to perform build"

./b2 "${_GENERIC_OPTS[@]}" \
     "${_TP_OPTS[@]}" \
     -j"${CPU_COUNT}" \
     stage 2>&1 | tee b2.build.log

echo "Information :: build.sh finished"

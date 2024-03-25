@echo on

:: Write python configuration, see https://github.com/boostorg/build/issues/194
@echo using python > user-config.jam
@echo : %PY_DUMMY_VER% >> user-config.jam
@echo : %PYTHON:\=\\% >> user-config.jam
@echo : %PREFIX:\=\\%\\include >> user-config.jam
@echo : %PREFIX:\=\\%\\libs >> user-config.jam
@echo ; >> user-config.jam
xcopy /Y user-config.jam %USERPROFILE%

:: Start with bootstrap
call bootstrap.bat
if %ERRORLEVEL% neq 0 exit 1

mkdir temp_prefix

:: Build step
.\b2 install ^
    --prefix=temp_prefix ^
    toolset=msvc-%VS_MAJOR%.0 ^
    address-model=%ARCH% ^
    variant=release ^
    threading=multi ^
    link=shared ^
    cxxstd=20 ^
    -s NO_COMPRESSION=0 ^
    -s NO_ZLIB=0 ^
    -s NO_BZIP2=0 ^
    -s ZLIB_INCLUDE=%LIBRARY_INC% ^
    -s ZLIB_LIBPATH=%LIBRARY_LIB% ^
    -s ZLIB_BINARY=z ^
    -s BZIP2_INCLUDE=%LIBRARY_INC% ^
    -s BZIP2_LIBPATH=%LIBRARY_LIB% ^
    -s BZIP2_BINARY=libbz2 ^
    -s ZSTD_INCLUDE=%LIBRARY_INC% ^
    -s ZSTD_LIBPATH=%LIBRARY_LIB% ^
    -s ZSTD_BINARY=zstd ^
    --layout=system ^
    -j%CPU_COUNT%
if %ERRORLEVEL% neq 0 exit 1

:: Set BOOST_AUTO_LINK_NOMANGLE so that auto-linking uses system layout
echo &echo.                           >> temp_prefix\include\boost\config\user.hpp
echo #define BOOST_AUTO_LINK_NOMANGLE >> temp_prefix\include\boost\config\user.hpp

:: we package the (python-version-independent) headers here, whereas the libs
:: are done in build-py.sh (because we need to build per python version)
del temp_prefix\lib\boost_python*.lib
del temp_prefix\lib\boost_python*.dll
del temp_prefix\lib\boost_numpy*.lib
del temp_prefix\lib\boost_numpy*.dll
rmdir /s /q temp_prefix\lib\cmake\boost_python-%PKG_VERSION%
rmdir /s /q temp_prefix\lib\cmake\boost_numpy-%PKG_VERSION%

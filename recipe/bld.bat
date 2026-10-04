@echo on

:: python 3.15 moved the windows headers from %PREFIX%\include into
:: %PREFIX%\include\python; ask python rather than hard-coding either layout
"%PYTHON%" -c "import sysconfig; print(sysconfig.get_config_var('INCLUDEPY'))" > py_include.txt
if %ERRORLEVEL% neq 0 exit 1
set /p PY_INC=<py_include.txt
del py_include.txt

:: Write python configuration, see https://github.com/boostorg/build/issues/194
@echo using python > user-config.jam
@echo : %python_min% >> user-config.jam
@echo : %PYTHON:\=\\% >> user-config.jam
@echo : %PY_INC:\=\\% >> user-config.jam
@echo : %PREFIX:\=\\%\\libs >> user-config.jam
@echo ; >> user-config.jam
xcopy /Y user-config.jam %USERPROFILE%

:: Start with bootstrap
call bootstrap.bat
if %ERRORLEVEL% neq 0 exit 1

:: bootstrap.bat turns off echo; turn it on again
@echo on

mkdir temp_prefix
mkdir temp_static_prefix

:: Build step
call :build_boost shared temp_prefix
if errorlevel 1 exit /b 1
call :build_boost static temp_static_prefix
if errorlevel 1 exit /b 1

:: Set BOOST_AUTO_LINK_NOMANGLE so that auto-linking uses system layout
echo &echo.                           >> temp_prefix\include\boost\config\user.hpp
echo #define BOOST_AUTO_LINK_NOMANGLE >> temp_prefix\include\boost\config\user.hpp

:: we package the (python-version-independent) headers here, whereas the libs
:: are done in build-py.sh (because we need to build per python version)
del temp_prefix\lib\boost_python*.lib
del temp_prefix\bin\boost_python*.dll
del temp_prefix\lib\boost_numpy*.lib
del temp_static_prefix\lib\boost_python*.lib
del temp_static_prefix\bin\boost_python*.dll
del temp_static_prefix\lib\boost_numpy*.lib
del temp_static_prefix\bin\boost_numpy*.dll
del temp_prefix\bin\boost_numpy*.dll
rmdir /s /q temp_prefix\lib\cmake\boost_python-%PKG_VERSION%
rmdir /s /q temp_prefix\lib\cmake\boost_numpy-%PKG_VERSION%

set MAX_NUMBER_OF_MEMBERS=200
erb boost\hana\detail\struct_macros.hpp.erb > temp_prefix\include\boost\hana\detail\struct_macros.hpp

goto :eof

:: Shared B2 options for both link modes.
:build_boost
.\b2 install ^
    --prefix=%~2 ^
    toolset=msvc-%VS_MAJOR%.0 ^
    address-model=%ARCH% ^
    variant=release ^
    threading=multi ^
    link=%~1 ^
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
exit /b %ERRORLEVEL%

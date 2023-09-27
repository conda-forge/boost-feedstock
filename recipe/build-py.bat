@echo on

:: Write python configuration, see https://github.com/boostorg/build/issues/194
@echo using python > user-config.jam
@echo : %PY_VER% >> user-config.jam
@echo : %PYTHON:\=\\% >> user-config.jam
@echo : %PREFIX:\=\\%\\include >> user-config.jam
@echo : %PREFIX:\=\\%\\libs >> user-config.jam
@echo ; >> user-config.jam
xcopy /Y user-config.jam %USERPROFILE%

:: clean up directory from bld.bat and reuse b2 built there
rmdir /s /q temp_prefix

mkdir build-py

:: Build step
.\b2 install ^
    --build-dir=build-py ^
    --prefix=%LIBRARY_PREFIX% ^
    toolset=msvc-%VS_MAJOR%.0 ^
    address-model=%ARCH% ^
    variant=release ^
    threading=multi ^
    link=shared ^
    --layout=system ^
    --with-python ^
    -j%CPU_COUNT%
if %ERRORLEVEL% neq 0 exit 1

:: clean up between builds for different python versions/implementations
rmdir /s /q build-py

:: Move dll's to LIBRARY_BIN
move %LIBRARY_LIB%\boost*.dll "%LIBRARY_BIN%"
if %ERRORLEVEL% neq 0 exit 1

:: remove CMake metadata from libboost-python; save it for libboost-python-dev
:: needs to be done separately per python version & implementation
mkdir %SRC_DIR%\cf_%PY_VER%_%python_impl%_cmake
move %LIBRARY_LIB%\cmake\boost_python-%PKG_VERSION% %SRC_DIR%\cf_%PY_VER%_%python_impl%_cmake\
move %LIBRARY_LIB%\cmake\boost_numpy-%PKG_VERSION% %SRC_DIR%\cf_%PY_VER%_%python_impl%_cmake\

:: Write python configuration, see https://github.com/boostorg/build/issues/194
@echo using python > user-config.jam
@echo : %PY_VER% >> user-config.jam
@echo : %PYTHON:\=\\% >> user-config.jam
@echo : %PREFIX:\=\\%\\include >> user-config.jam
@echo : %PREFIX:\=\\%\\libs >> user-config.jam
@echo ; >> user-config.jam
xcopy user-config.jam %USERPROFILE%

:: clean up directory from bld.bat and reuse b2 built there
rmdir /s /q temp_prefix

:: Build step
.\b2 install ^
    --build-dir=buildboost ^
    --prefix=%LIBRARY_PREFIX% ^
    toolset=msvc-%VS_MAJOR%.0 ^
    address-model=%ARCH% ^
    variant=release ^
    threading=multi ^
    link=shared ^
    --layout=system ^
    --with-python ^
    -j%CPU_COUNT%
if errorlevel 1 exit 1

:: Move dll's to LIBRARY_BIN
move %LIBRARY_LIB%\boost*.dll "%LIBRARY_BIN%"
if errorlevel 1 exit 1


@echo on

:: see build-py.bat
xcopy /E /Y %SRC_DIR%\cf_%PY_VER%_cmake %LIBRARY_LIB%\cmake

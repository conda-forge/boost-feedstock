@echo on

:: see build-py.bat
xcopy /E /Y %SRC_DIR%\cf_%PY_VER%_%python_impl%_cmake %LIBRARY_LIB%\cmake

@echo on

:: see build-py.bat
xcopy /E /Y %SRC_DIR%\cf_%PY_VER%_%python_impl%_cmake %LIBRARY_LIB%\cmake
:: Patch CMake configs so IMPORTED_LOCATION for DLLs points to bin/ not lib/
python "%RECIPE_DIR%\fix-cmake-dll-paths.py" %LIBRARY_LIB%\cmake
if %ERRORLEVEL% neq 0 exit 1

@echo on

:: for libboost-headers, only the headers
robocopy temp_prefix\include %LIBRARY_INC% /E

:: everything else
if [%PKG_NAME%] == [libboost] (
    robocopy temp_prefix\lib %LIBRARY_LIB% /E
    REM Move dll's to LIBRARY_BIN
    move %LIBRARY_LIB%\boost*.dll "%LIBRARY_BIN%"
)

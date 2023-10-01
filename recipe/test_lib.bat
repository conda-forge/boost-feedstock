:: Test boost::iostreams zlib filter support
@echo on

cd test

cl.exe /EHsc /MD /DBOOST_ALL_DYN_LINK /DBOOST_ZLIB_BINARY=kernel32 /I%PREFIX%\Library\include test_iostreams_zlib.cpp /link /libpath:%PREFIX%\Library\lib
if %ERRORLEVEL% neq 0 exit 1

test_iostreams_zlib.exe
if %ERRORLEVEL% neq 0 exit 1

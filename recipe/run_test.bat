:: Test boost::iostreams zlib filter support
cd test
cl.exe /EHsc /MD /DBOOST_ALL_DYN_LINK /DBOOST_ZLIB_BINARY=kernel32 /I%PREFIX%\Library\include test_iostreams_zlib.cpp /link /libpath:%PREFIX%\Library\lib
if errorlevel 1 exit 1

test_iostreams_zlib.exe
if errorlevel 1 exit 1

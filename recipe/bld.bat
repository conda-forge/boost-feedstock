:: Start with bootstrap
call bootstrap.bat
if errorlevel 1 exit 1

:: Build step
.\b2 install ^
    --build-dir=buildboost ^
    --prefix=%LIBRARY_PREFIX% ^
    toolset=msvc-%VS_MAJOR%.0 ^
    address-model=%ARCH% ^
    variant=release ^
    threading=multi ^
    link=static,shared ^
    -j%CPU_COUNT% ^
    --layout=system ^
    --without-python
if errorlevel 1 exit 1

:: Remove Python headers as we don't build Boost.Python.
del %LIBRARY_INC%\boost\python.hpp
rmdir /s /q %LIBRARY_INC%\boost\python

:: Move dll's to LIBRARY_BIN
move %LIBRARY_LIB%\boost*.dll "%LIBRARY_BIN%"
if errorlevel 1 exit 1

:: Set BOOST_AUTO_LINK_NOMANGLE so that auto-linking uses system layout
echo &echo.                           >> %LIBRARY_INC%\boost\config\user.hpp
echo #define BOOST_AUTO_LINK_NOMANGLE >> %LIBRARY_INC%\boost\config\user.hpp


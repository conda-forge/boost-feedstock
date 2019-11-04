set LogFile=b2.install.log
set TempLog=b2.install.log.tmp
set LogTee=^> %TempLog%^&^& type %TempLog%^&^&type %TempLog%^>^>%LogFile%

echo on

:: set WITHOUTS=--without-python --with-atomic --without-chrono --without-container --without-context --without-contract --without-coroutine --without-date_time --without-exception --without-fiber --without-filesystem --without-graph --without-graph_parallel --without-iostreams --without-locale --without-log --without-math --without-mpi --without-program_options --without-random --without-regex --without-serialization --without-signals --without-stacktrace --without-system --without-test --without-thread --without-timer --without-type_erasure --without-wave
set WITHOUTS=--without-python

:: Build step
.\b2                         ^
  -q -d+2 --debug            ^
  --prefix=%LIBRARY_PREFIX%  ^
  toolset=msvc-%vc%.0        ^
  address-model=%ARCH%       ^
  variant=release            ^
  threading=multi            ^
  link=static,shared         ^
  --layout=versioned         ^
  -j%CPU_COUNT%              ^
  %WITHOUTS%                 ^
  install                    ^
  %LogTee%


:: Get the major_minor_patch version info, e.g. `1_61_1`. In
:: the past this has been just major_minor, so we do not just
:: replace all dots with underscores in case it changes again
for /F "tokens=1,2,3 delims=." %%a in ("%PKG_VERSION%") do (
   set MAJ=%%a
   set MIN=%%b
   set PAT=%%c
)
set MAJ_MIN_PAT_VER=%MAJ%_%MIN%_%PAT%
set MAJ_MIN_VER=%MAJ%_%MIN%

:: Install fix-up for a non version-specific boost include
move %LIBRARY_INC%\boost-%MAJ_MIN_VER%\boost %LIBRARY_INC%
if errorlevel 1 exit /b 1

:: Remove Python headers as we don't build Boost.Python.
if exist %LIBRARY_INC%\boost\python.hpp del %LIBRARY_INC%\boost\python.hpp
if exist %LIBRARY_INC%\boost\python rmdir /s /q %LIBRARY_INC%\boost\python

if %ARCH% == 32 (
  set ARCH_STRING=x32
) else (
  set ARCH_STRING=x64
)

:: Move DLLs to LIBRARY_BIN
move %LIBRARY_LIB%\*vc%vc%0-mt-%ARCH_STRING%-%MAJ_MIN_VER%.dll "%LIBRARY_BIN%"
if errorlevel 1 exit /b 1

copy .\b2.exe %LIBRARY_BIN%\b2.exe
if errorlevel 1 exit /b 1
copy .\b2.exe %LIBRARY_BIN%\bjam.exe
if errorlevel 1 exit /b 1

mkdir "%LIBRARY_PREFIX%\share\boost-build\src\build"
mkdir "%LIBRARY_PREFIX%\share\boost-build\src\kernel"
mkdir "%LIBRARY_PREFIX%\share\boost-build\src\options"
mkdir "%LIBRARY_PREFIX%\share\boost-build\src\tools"
mkdir "%LIBRARY_PREFIX%\share\boost-build\src\util"
pushd tools\build\src
  robocopy /E build   "%LIBRARY_PREFIX%\share\boost-build\src\build"
  robocopy /E kernel  "%LIBRARY_PREFIX%\share\boost-build\src\kernel"
  robocopy /E options "%LIBRARY_PREFIX%\share\boost-build\src\options"
  robocopy /E tools   "%LIBRARY_PREFIX%\share\boost-build\src\tools"
  robocopy /E util    "%LIBRARY_PREFIX%\share\boost-build\src\util"
popd
pushd tools\build
  copy *.jam "%LIBRARY_PREFIX%\share\boost-build"
popd
exit /b 0

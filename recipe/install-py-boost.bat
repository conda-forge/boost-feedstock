echo on

:: if exist C:\Users\builder\py-boost-%PY_VER%-before-clean rd /s /q C:\Users\builder\py-boost-%PY_VER%-before-clean > NUL
:: mkdir C:\Users\builder\py-boost-%PY_VER%-before-clean
:: xcopy %CD% C:\Users\builder\py-boost-%PY_VER%-before-clean /s /e /h /q /y

set INSTLOC=%CD%\py-boost-inst-%PY_VER%

:: if exist C:\Users\builder\py-boost-%PY_VER%-after-clean rd /s /q C:\Users\builder\py-boost-%PY_VER%-after-clean > NUL
:: mkdir C:\Users\builder\py-boost-%PY_VER%-after-clean
:: xcopy %CD% C:\Users\builder\py-boost-%PY_VER%-after-clean /s /e /h /q /y

:: if exist C:\Users\builder\py-boost-%PY_VER%-after-build rd /s /q C:\Users\builder\py-boost-%PY_VER%-after-build > NUL
:: mkdir C:\Users\builder\py-boost-%PY_VER%-after-build

:: No idea, luckily it is far from slow.
for /L %%A IN (1,1,2) DO (
  .\b2 ^
    -q -d+2 --debug ^
    --prefix=%INSTLOC% ^
    toolset=msvc-%vc%.0 ^
    address-model=%ARCH% ^
    variant=release ^
    threading=multi ^
    link=static,shared ^
    -j1 ^
    --with-python ^
    --reconfigure ^
    python=%PY_VER% ^
    clean

  .\b2 ^
    -q -d+2 --debug ^
    --prefix=%INSTLOC% ^
    toolset=msvc-%vc%.0 ^
    address-model=%ARCH% ^
    variant=release ^
    threading=multi ^
    link=static,shared ^
    -j1 ^
    --with-python ^
    --reconfigure ^
    python=%PY_VER% ^
    install
)

:: xcopy %CD% C:\Users\builder\py-boost-%PY_VER%-after-build /s /e /h /q /y

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
:: echo move %INSTLOC%\include\boost-%MAJ_MIN_VER%\boost %LIBRARY_INC%\boost
move %INSTLOC%\include\boost-%MAJ_MIN_VER%\boost\python %LIBRARY_INC%\boost\
move %INSTLOC%\include\boost-%MAJ_MIN_VER%\boost\python.hpp %LIBRARY_INC%\boost\
if errorlevel 1 exit /b 1

if %ARCH% == 32 (
  set ARCH_STRING=x32
) else (
  set ARCH_STRING=x64
)

:: Spent too long on this. Hopefully the clean command is now correct. If not you'll find objs that
:: contain e.g. DEFAULT:python37.lib when linking to Python 3.6 and those need to be removed.
if not exist %INSTLOC%\lib\boost_python%CONDA_PY%-vc%vc%0-mt-%ARCH_STRING%-%MAJ_MIN_VER%.dll exit /b 1
if not exist %INSTLOC%\lib\boost_numpy%CONDA_PY%-vc%vc%0-mt-%ARCH_STRING%-%MAJ_MIN_VER%.dll exit /b 1

:: Move DLL to LIBRARY_BIN
move %INSTLOC%\lib\*vc%vc%0-mt-%ARCH_STRING%-%MAJ_MIN_VER%.dll "%LIBRARY_BIN%"
if errorlevel 1 exit /b 1
move %INSTLOC%\lib\*vc%vc%0-mt-%ARCH_STRING%-%MAJ_MIN_VER%.lib "%LIBRARY_LIB%"
if errorlevel 1 exit /b 1

:: remove any old builds of the python target
.\b2 ^
  -q -d+2 --debug ^
  --prefix=%INSTLOC% ^
  toolset=msvc-%vc%.0 ^
  address-model=%ARCH% ^
  variant=release ^
  threading=multi ^
  link=static,shared ^
  -j1 ^
  --with-python ^
  --reconfigure ^
  python=%PY_VER% ^
  clean python

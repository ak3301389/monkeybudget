@echo off
chcp 65001 >nul
cd /d D:\home_budget_mob

for /f "tokens=2" %%a in ('findstr /b "version:" pubspec.yaml') do set "full_ver=%%a"

for /f "tokens=1 delims=+" %%a in ("%full_ver%") do set "ver_part=%%a"
for /f "tokens=1-3 delims=." %%a in ("%ver_part%") do (
  set "major=%%a"
  set "minor=%%b"
  set "patch=%%c"
)

for /f "tokens=2 delims=+" %%a in ("%full_ver%") do set "old_build=%%a"
if "%old_build%"=="" set "old_build=0"

echo.
echo Current version: %major%.%minor%.%patch%.%old_build%
echo.
echo Vyberite tip:
echo 1 - Ispravlenie (Patch)
echo 2 - Novaya funkciya (Minor)
echo 3 - Krupnoe izmenenie (Major)
echo 4 - Prosto peresborka (Build)
set /p version_type="Tip (1-4): "

if "%version_type%"=="1" (
  set /a patch=patch+1
  set /a build_num=old_build+1
)
if "%version_type%"=="2" (
  set /a minor=minor+1
  set patch=0
  set /a build_num=old_build+1
)
if "%version_type%"=="3" (
  set /a major=major+1
  set minor=0
  set patch=0
  set /a build_num=old_build+1
)
if "%version_type%"=="4" (
  set /a build_num=old_build+1
)

set /p comment="Comment: "

powershell -Command "(Get-Content pubspec.yaml) -replace 'version: .*', 'version: %major%.%minor%.%patch%+%build_num%' | Set-Content pubspec.yaml"

echo v%major%.%minor%.%patch%.%build_num% - %comment% >> version_history.txt

echo.
echo === BUILDING APK ===
call D:\flutter\bin\flutter.bat build apk --release --no-tree-shake-icons

if errorlevel 1 (
  echo APK ERROR! But continue...
)

mkdir release 2>nul

set "apk_name=homebudget.v%major%.%minor%.%patch%.%build_num%.apk"
copy "build\app\outputs\flutter-apk\app-release.apk" "release\%apk_name%"

echo Done! APK: release\%apk_name%

echo.
echo === BUILDING WEB ===
call D:\flutter\bin\flutter.bat build web --release --no-tree-shake-icons

if errorlevel 1 (
  echo WEB ERROR!
)

echo Done! Web: build\web\

echo.
echo === DEPLOY TO FIREBASE ===
call firebase deploy --only hosting:monkeybudget

if errorlevel 1 (
  echo FIREBASE ERROR!
) else (
  echo Deployed to https://monkeybudget.web.app
)

echo.
echo === ALL DONE ===
echo APK: release\%apk_name%
echo Web: https://monkeybudget.web.app
pause
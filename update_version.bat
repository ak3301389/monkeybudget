@echo off
cd /d D:\home_budget_mob

REM Читаем текущую версию
for /f "tokens=2 delims=:+" %%a in ('findstr "version:" pubspec.yaml') do (
  set "ver=%%a"
)

echo Current version: %ver%

REM Увеличиваем build number
for /f "tokens=1-3 delims=.+" %%a in ("%ver%") do (
  set "major=%%a"
  set "minor=%%b"
  set "patch=%%c"
)

set /a build_num=%ver:*+=%+1

REM Обновляем pubspec.yaml
powershell -Command "(Get-Content pubspec.yaml) -replace 'version: .*', 'version: %major%.%minor%.%patch%+%build_num%' | Set-Content pubspec.yaml"

echo New version: %major%.%minor%.%patch%+%build_num%
pause
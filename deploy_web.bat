@echo off
cd /d D:\home_budget_mob
echo Building web...
call D:\flutter\bin\flutter.bat build web --release --no-tree-shake-icons
if errorlevel 1 (
  echo BUILD FAILED
  pause
  exit /b 1
)
echo Deploying to Firebase...
call "C:\Users\33013\AppData\Roaming\npm\firebase.cmd" deploy --only hosting:monkeybudget
if errorlevel 1 (
  echo DEPLOY FAILED
  pause
  exit /b 1
)
echo Done! https://budget.dedars.ru
pause
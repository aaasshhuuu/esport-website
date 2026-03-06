@echo off
setlocal
cd /d "%~dp0"

echo.
echo Neon Arena - One-click runner
echo -----------------------------
echo This will install deps (first time) and start SERVER + CLIENT.
echo.

npm install
if errorlevel 1 goto :fail

npm run setup
if errorlevel 1 goto :fail

npm run dev
goto :eof

:fail
echo.
echo Failed to start Neon Arena. See output above.
pause
exit /b 1


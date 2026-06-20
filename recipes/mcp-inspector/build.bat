@echo off
setlocal

SET INSTALL_DIR=%PREFIX%\lib\mcp-inspector

:: Install dependencies and build all TypeScript workspaces
call npm ci
if %ERRORLEVEL% neq 0 exit /b 1

call npm run build
if %ERRORLEVEL% neq 0 exit /b 1

:: Copy built workspace directories preserving the relative structure that
:: cli/build/cli.js relies on for locating the client and server.
if not exist "%INSTALL_DIR%\cli\build" mkdir "%INSTALL_DIR%\cli\build"
xcopy /E /I /Q /Y cli\build "%INSTALL_DIR%\cli\build\"
if errorlevel 4 exit /b 1

if not exist "%INSTALL_DIR%\server\build" mkdir "%INSTALL_DIR%\server\build"
xcopy /E /I /Q /Y server\build "%INSTALL_DIR%\server\build\"
if errorlevel 4 exit /b 1

if exist server\static (
    xcopy /E /I /Q /Y server\static "%INSTALL_DIR%\server\static\"
    if errorlevel 4 exit /b 1
)

if not exist "%INSTALL_DIR%\client" mkdir "%INSTALL_DIR%\client"
if exist client\dist (
    xcopy /E /I /Q /Y client\dist "%INSTALL_DIR%\client\dist\"
    if errorlevel 4 exit /b 1
)
if exist client\bin (
    xcopy /E /I /Q /Y client\bin "%INSTALL_DIR%\client\bin\"
    if errorlevel 4 exit /b 1
)

:: robocopy follows directory junctions (npm workspace links) automatically.
:: Exit codes 0-7 indicate success; 8+ indicate errors.
robocopy node_modules "%INSTALL_DIR%\node_modules" /E /NFL /NDL /NJH /NJS /NC /NS
if errorlevel 8 exit /b 1

:: Scripts\ is on PATH in conda environments on Windows
if not exist "%PREFIX%\Scripts" mkdir "%PREFIX%\Scripts"
copy /Y "%RECIPE_DIR%\mcp-inspector.bat" "%PREFIX%\Scripts\mcp-inspector.bat"
if %ERRORLEVEL% neq 0 exit /b 1

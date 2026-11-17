@echo off
title ANITS College Game Launcher
cd /d "%~dp0"

echo ===================================================
echo       Starting ANITS College Simulation
echo ===================================================

where node >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo [Environment detected: Node.js]
    node server.js
    goto end
)

where python >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo [Environment detected: Python]
    start http://localhost:3000
    python -m http.server 3000
    goto end
)

echo [Environment: Native Windows (No Node/Python required)]
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0server.ps1"

:end
pause

@echo off
title Nitro Underground
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0gioca-nitro.ps1"
if errorlevel 1 (
  echo.
  echo Qualcosa e' andato storto: copia il messaggio qui sopra e mandalo a Claude.
  pause
) else (
  timeout /t 5
)

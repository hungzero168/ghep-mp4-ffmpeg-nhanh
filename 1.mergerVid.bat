@echo off
setlocal

rem Batch (tier) size
set BATCH=6

rem Ensure __parts exists and clean old parts
if exist __parts rd /s /q __parts
mkdir __parts >nul 2>nul

rem Delegate complex logic to a PowerShell script to avoid quoting bugs
powershell -NoProfile -ExecutionPolicy Bypass -File "__merge_parts.ps1" -BATCH %BATCH%

echo Done.

endlocal

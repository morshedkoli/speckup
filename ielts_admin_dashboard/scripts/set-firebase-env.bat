@echo off
REM Set Firebase environment variables for production deployment
REM Usage: scripts\set-firebase-env.bat

echo === Setting Firebase Secrets ===
echo.

REM Check if .env.local exists
if not exist ".env.local" (
    echo Error: .env.local not found
    exit /b 1
)

REM Use PowerShell to parse and set secrets
powershell -Command ^
  "Get-Content .env.local | ForEach-Object { ^
    if ($_ -match '^([^#=]+)=(.*)$' -and $_ -notmatch '^NEXT_PUBLIC_') { ^
      $key = $matches[1].Trim(); ^
      $value = $matches[2].Trim() -replace '^[''\"]|[''\"\]$',''; ^
      if ($value) { ^
        Write-Host \"Setting $key...\"; ^
        firebase functions:secrets:set $key --value $value --quiet ^
      } ^
    } ^
  }"

echo.
echo === Done ===
echo.
echo Note: NEXT_PUBLIC_* variables are embedded at build time.

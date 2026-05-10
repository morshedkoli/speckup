@echo off
REM Deploy to Firebase Hosting with environment variables
REM Usage: scripts\deploy.bat

echo === Deploying to Firebase Hosting ===
echo.

REM Check if .env.local exists
if not exist ".env.local" (
    echo Error: .env.local not found
    exit /b 1
)

REM Create .env file for Firebase deployment (build-time variables)
echo Creating .env for build-time environment variables...
findstr /B "NEXT_PUBLIC_" .env.local > .env 2>nul || echo. > .env

REM Set Firebase secrets (runtime variables)
echo.
echo Setting Firebase secrets...

REM Parse .env.local and set secrets using PowerShell
powershell -Command "Get-Content .env.local | ForEach-Object { if ($_ -match '^([^#=]+)=(.*)$' -and $_ -notmatch '^NEXT_PUBLIC_') { $key=$matches[1].Trim(); $value=$matches[2].Trim() -replace '^[''\"]|[''\"\]$',''; if($value) { Write-Host \"  Setting $key...\"; firebase functions:secrets:set $key --value $value --quiet } } }"

REM Build the Next.js app with environment variables
echo.
echo Building Next.js app...
for /f "delims==" %%a in ('findstr /B "NEXT_PUBLIC_" .env.local') do set "%%a"
npm run build

REM Deploy to Firebase
echo.
echo Deploying to Firebase Hosting...
firebase deploy --only hosting

REM Cleanup
del .env 2>nul

echo.
echo === Deployment Complete ===

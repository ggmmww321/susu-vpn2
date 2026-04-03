@echo off
chcp 65001 >nul
echo ============================================
echo Susu VPN2 - Simple Build Script
echo ============================================
echo.

REM Step 1: Check Git
echo [Step 1] Check Git...
"C:\Program Files\Git\bin\git.exe" --version >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Git not found at C:\Program Files\Git\bin\git.exe
    echo Please confirm Git is installed at this location
    pause
    exit /b 1
)
echo [OK] Git found: C:\Program Files\Git\bin\git.exe

REM Step 2: Initialize Git repository
echo.
echo [Step 2] Initialize Git repository...
if exist ".git" (
    echo [OK] Already a Git repository
) else (
    "C:\Program Files\Git\bin\git.exe" init
    echo [OK] Git repository initialized
)

REM Step 3: Create .gitignore
echo.
echo [Step 3] Create .gitignore file...
(
echo # Build
echo build/
echo .dart_tool/
echo .packages
echo .pub-cache/
echo .pub/
echo.
echo # IDE
echo .vscode/
echo .idea/
echo *.swp
echo *.swo
echo *~
echo.
echo # Android
echo *.apk
echo *.aab
echo local.properties
echo .gradle/
) > .gitignore
echo [OK] .gitignore created

REM Step 4: Add files to Git (simplified - always add)
echo.
echo [Step 4] Add files to Git...
"C:\Program Files\Git\bin\git.exe" add .

REM Step 5: Commit changes (simplified - always commit)
echo [Step 5] Commit changes...
"C:\Program Files\Git\bin\git.exe" commit -m "Initial commit: Susu VPN2 app" || (
    echo [INFO] No changes to commit or already committed
)

REM Step 6: Check GitHub CLI
echo.
echo [Step 6] Check GitHub CLI...
where gh >nul 2>nul
if %errorlevel% neq 0 (
    echo [WARN] GitHub CLI not installed
    echo.
    echo Please install GitHub CLI: https://cli.github.com/
    echo After installation, run: gh auth login
    echo.
    echo Or create GitHub repository manually:
    echo 1. Visit https://github.com/new
    echo 2. Create repository: susu-vpn2
    echo 3. Follow instructions to upload code
    pause
    exit /b 1
)

REM Step 7: Check GitHub login
echo Check GitHub login status...
gh auth status >nul 2>nul
if %errorlevel% neq 0 (
    echo [WARN] Not logged in to GitHub
    echo Please run: gh auth login
    pause
    exit /b 1
)

REM Step 8: Get GitHub info
echo.
set /p GITHUB_USERNAME=Enter your GitHub username: 
if "%GITHUB_USERNAME%"=="" (
    echo ERROR: GitHub username is required
    pause
    exit /b 1
)

REM Step 9: Create GitHub repository
echo.
echo [Step 9] Create GitHub repository...
gh repo create susu-vpn2 --public --source=. --remote=origin --push

if %errorlevel% neq 0 (
    echo [ERROR] Failed to create repository
    echo.
    echo You can create manually:
    echo 1. Visit: https://github.com/%GITHUB_USERNAME%/susu-vpn2
    echo 2. Click "Create repository"
    echo 3. Then run these commands:
    echo    "C:\Program Files\Git\bin\git.exe" remote add origin https://github.com/%GITHUB_USERNAME%/susu-vpn2.git
    echo    "C:\Program Files\Git\bin\git.exe" branch -M main
    echo    "C:\Program Files\Git\bin\git.exe" push -u origin main
    pause
    exit /b 1
)

REM Step 10: Success
echo.
echo ============================================
echo BUILD TRIGGERED!
echo ============================================
echo.
echo [SUCCESS] Code pushed to GitHub!
echo.
echo Next steps:
echo 1. Visit your repository: https://github.com/%GITHUB_USERNAME%/susu-vpn2
echo 2. Click "Actions" tab to see build progress
echo 3. Wait 5-10 minutes for build to complete
echo 4. Download APK from "Releases" tab
echo.
echo After build completes, you will get Susu VPN2 APK!
echo.
pause
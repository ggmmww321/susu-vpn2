@echo off
echo ===============================================
echo Susu VPN2 - Quick GitHub Push & Build
echo ===============================================
echo.

REM Step 1: Check Git
where git >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Git is not installed!
    echo Please install Git from: https://git-scm.com/download/win
    pause
    exit /b 1
)

echo [OK] Git found: %git_version%

REM Step 2: Initialize Git if needed
if exist ".git" (
    echo [OK] Already a Git repository
) else (
    echo Initializing Git repository...
    git init
    echo [OK] Git repository initialized
)

REM Step 3: Create .gitignore
echo Creating .gitignore...
(
echo # Build
echo build/
echo .dart_tool/
echo .packages
echo .pub-cache/
echo .pub/
echo 
echo # IDE
echo .vscode/
echo .idea/
echo *.swp
echo *.swo
echo *~
echo 
echo # OS
echo .DS_Store
echo Thumbs.db
echo 
echo # Flutter
echo /flutter/
echo 
echo # Android
echo *.apk
echo *.aab
echo local.properties
echo .gradle/
echo 
echo # Logs
echo *.log
echo logs/
echo 
echo # v2ray temp files
echo scripts/v2ray_*/
) > .gitignore
echo [OK] .gitignore created

REM Step 4: Add and commit
echo Adding files to Git...
git add .

echo Checking for changes...
git status --porcelain > temp_status.txt
set /p status=<temp_status.txt
del temp_status.txt

if "%status%"=="" (
    echo [INFO] No changes to commit
) else (
    echo Committing changes...
    git commit -m "Initial commit: Susu VPN2 app
    
    Features:
    - Cross-platform VPN client (Flutter + Android)
    - Supports VMess/VLESS/Trojan/Shadowsocks protocols
    - Built-in subscription URL
    - Android VPN Service integration
    - v2ray-core engine
    
    Build:
    - GitHub Actions auto-build
    - Android SDK 34 + Java 17
    - Flutter 3.19.6"
    echo [OK] Changes committed
)

REM Step 5: Create GitHub repository
echo.
echo ===============================================
echo GITHUB REPOSITORY SETUP
echo ===============================================
echo.

REM Get GitHub username
set /p GITHUB_USERNAME=Enter your GitHub username: 
if "%GITHUB_USERNAME%"=="" (
    echo ERROR: GitHub username is required
    pause
    exit /b 1
)

REM Check GitHub authentication
echo Checking GitHub authentication...
gh auth status >nul 2>nul
if %errorlevel% neq 0 (
    echo GitHub CLI is not authenticated.
    echo Please login to GitHub CLI using: gh auth login
    pause
    exit /b 1
)

REM Create repository
echo Creating repository %RepoName% on GitHub...
gh repo create %RepoName% --public --source=. --remote=origin --push

if %errorlevel% neq 0 (
    echo ERROR: Failed to create repository
    echo You may need to manually create it at:
    echo https://github.com/%GITHUB_USERNAME%/%RepoName%
    echo Then run: git remote add origin https://github.com/%GITHUB_USERNAME%/%RepoName%.git
    echo And: git push -u origin main
    pause
    exit /b 1
)

echo [OK] Repository created and pushed to GitHub

REM Step 6: Show next steps
echo.
echo ===============================================
echo NEXT STEPS
echo ===============================================
echo.
echo 1. Go to your repository:
echo    https://github.com/%GITHUB_USERNAME%/%RepoName%
echo.
echo 2. The GitHub Actions build will start automatically.
echo    Check the "Actions" tab in your repository.
echo.
echo 3. Wait 5-10 minutes for build to complete.
echo.
echo 4. Download APK from:
echo    https://github.com/%GITHUB_USERNAME%/%RepoName%/releases
echo.
echo ===============================================
echo SUCCESS! Build has been triggered.
echo ===============================================

pause
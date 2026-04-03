# Git Fix Push Script - Uses full Git path
# This script handles Git not being in PATH

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Functions
function Write-Step { param($msg) Write-Host "`n" + ("="*40) -ForegroundColor Cyan; Write-Host " $msg" -ForegroundColor Cyan; Write-Host ("="*40) -ForegroundColor Cyan }
function Write-OK { param($m) Write-Host "[OK] $m" -ForegroundColor Green }
function Write-FAIL { param($m) Write-Host "[FAIL] $m" -ForegroundColor Red }

# Step 1: Find Git
Write-Step "Step 1: Find Git Installation"

$gitPath = $null
$commonGitPaths = @(
    "C:\Program Files\Git\bin\git.exe",
    "C:\Program Files (x86)\Git\bin\git.exe", 
    "$env:USERPROFILE\AppData\Local\Programs\Git\bin\git.exe",
    "C:\git\bin\git.exe"
)

foreach ($path in $commonGitPaths) {
    if (Test-Path $path) {
        $gitPath = $path
        Write-OK "Found Git at: $path"
        break
    }
}

if (-not $gitPath) {
    Write-FAIL "Git not found in common locations."
    Write-Host ""
    Write-Host "Please install Git from: https://git-scm.com/download/win" -ForegroundColor Yellow
    Write-Host "Make sure to check 'Add Git to PATH' during installation." -ForegroundColor Yellow
    exit 1
}

# Function to run git commands with full path
function Run-Git {
    param([string]$arguments)
    & $gitPath $arguments.Split(" ")
}

# Step 2: Initialize Git
Write-Step "Step 2: Initialize Git Repository"
if (Test-Path ".git") {
    Write-OK "Already a Git repository"
} else {
    Run-Git "init"
    Write-OK "Git repository initialized"
}

# Step 3: Create .gitignore
Write-Step "Step 3: Create .gitignore"
$gitignoreContent = @"
# Build
build/
.dart_tool/
.packages
.pub-cache/
.pub/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Flutter
/flutter/

# Android
*.apk
*.aab
local.properties
.gradle/

# Logs
*.log
logs/

# v2ray temp files
scripts/v2ray_*/
"@

if (-not (Test-Path ".gitignore")) {
    $gitignoreContent | Out-File ".gitignore" -Encoding UTF8
    Write-OK "Created .gitignore file"
} else {
    Write-OK ".gitignore already exists"
}

# Step 4: Commit changes
Write-Step "Step 4: Commit Changes"
Run-Git "add ."

$status = Run-Git "status --porcelain"
if ($status) {
    Run-Git 'commit -m "Initial commit: Susu VPN2 app

Features:
- Cross-platform VPN client (Flutter + Android)
- Supports VMess/VLESS/Trojan/Shadowsocks protocols
- Built-in subscription URL
- Android VPN Service integration
- v2ray-core engine

Build:
- GitHub Actions auto-build
- Android SDK 34 + Java 17
- Flutter 3.19.6"'
    Write-OK "Changes committed"
} else {
    Write-OK "No changes to commit"
}

# Step 5: Check GitHub CLI
Write-Step "Step 5: Check GitHub CLI"
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-FAIL "GitHub CLI not installed. Install from: https://cli.github.com/"
    Write-Host "After installing, run: gh auth login" -ForegroundColor Yellow
    exit 1
}

# Check auth
$authStatus = gh auth status 2>&1
if ($authStatus -match "not logged") {
    Write-FAIL "GitHub CLI not authenticated. Run: gh auth login"
    exit 1
}
Write-OK "GitHub CLI authenticated"

# Step 6: Get GitHub info
Write-Step "Step 6: GitHub Setup"
$githubUsername = Read-Host "Enter your GitHub username"
if (-not $githubUsername) {
    Write-FAIL "GitHub username is required"
    exit 1
}

$repoName = Read-Host "Enter repository name [susu-vpn2]"
if (-not $repoName) { $repoName = "susu-vpn2" }

# Step 7: Create repository
Write-Step "Step 7: Create GitHub Repository"
Write-Host "Creating repository: $repoName" -ForegroundColor Cyan

try {
    gh repo create $repoName --public --source=. --remote=origin --push
    Write-OK "Repository created and pushed to GitHub"
} catch {
    Write-FAIL "Failed to create repository"
    Write-Host "You can create it manually at:" -ForegroundColor Yellow
    Write-Host "https://github.com/$githubUsername/$repoName" -ForegroundColor Yellow
    Write-Host "Then run these commands:" -ForegroundColor Yellow
    Write-Host "Run-Git `"remote add origin https://github.com/$githubUsername/$repoName.git`"" -ForegroundColor White
    Write-Host "Run-Git `"branch -M main`"" -ForegroundColor White
    Write-Host "Run-Git `"push -u origin main`"" -ForegroundColor White
    exit 1
}

# Step 8: Show success
Write-Step "SUCCESS - Build Triggered"
Write-Host "Your repository:" -ForegroundColor Green
Write-Host "https://github.com/$githubUsername/$repoName" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Green
Write-Host "1. Go to your repository URL above" -ForegroundColor White
Write-Host "2. Click 'Actions' tab to see build progress" -ForegroundColor White
Write-Host "3. Wait 5-10 minutes for build to complete" -ForegroundColor White
Write-Host "4. Download APK from 'Releases' tab" -ForegroundColor White
Write-Host ""
Write-Host "Build should start automatically!" -ForegroundColor Green
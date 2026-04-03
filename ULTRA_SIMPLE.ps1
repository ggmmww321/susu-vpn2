# Ultra Simple Build Script
# Just run the essential commands

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Ultra Simple Build Script" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Initialize Git if needed
Write-Host "[1/5] Initializing Git..." -ForegroundColor Yellow
if (-not (Test-Path ".git")) {
    & "C:\Program Files\Git\bin\git.exe" init
    Write-Host "  Git repository created" -ForegroundColor Green
} else {
    Write-Host "  Git repository already exists" -ForegroundColor Green
}

# Step 2: Add and commit
Write-Host "[2/5] Adding files..." -ForegroundColor Yellow
& "C:\Program Files\Git\bin\git.exe" add .

Write-Host "[3/5] Committing changes..." -ForegroundColor Yellow
& "C:\Program Files\Git\bin\git.exe" commit -m "Initial commit: Susu VPN2 app"
Write-Host "  Changes committed" -ForegroundColor Green

# Step 3: Check GitHub CLI
Write-Host "[4/5] Checking GitHub CLI..." -ForegroundColor Yellow
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "  ERROR: GitHub CLI not installed" -ForegroundColor Red
    Write-Host "  Download from: https://cli.github.com/" -ForegroundColor Yellow
    Write-Host "  After installing, run: gh auth login" -ForegroundColor Yellow
    exit
}
Write-Host "  GitHub CLI found" -ForegroundColor Green

# Step 4: Get GitHub username
Write-Host "[5/5] Creating GitHub repository..." -ForegroundColor Yellow
$username = Read-Host "  Enter your GitHub username"
if (-not $username) {
    Write-Host "  ERROR: Username required" -ForegroundColor Red
    exit
}

# Step 5: Create repository
try {
    gh repo create susu-vpn2 --public --source=. --remote=origin --push
    Write-Host "  Repository created!" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host "SUCCESS! Build triggered." -ForegroundColor Green
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your repository: https://github.com/$username/susu-vpn2" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Go to the URL above" -ForegroundColor White
    Write-Host "2. Click 'Actions' tab" -ForegroundColor White
    Write-Host "3. Wait 5-10 minutes" -ForegroundColor White
    Write-Host "4. Download APK from 'Releases'" -ForegroundColor White
} catch {
    Write-Host "  ERROR: Failed to create repository" -ForegroundColor Red
    Write-Host ""
    Write-Host "Manual steps:" -ForegroundColor Yellow
    Write-Host "1. Visit: https://github.com/new" -ForegroundColor White
    Write-Host "2. Create repository 'susu-vpn2'" -ForegroundColor White
    Write-Host "3. Then run these commands:" -ForegroundColor White
    Write-Host '   & "C:\Program Files\Git\bin\git.exe" remote add origin https://github.com/' + $username + '/susu-vpn2.git' -ForegroundColor Gray
    Write-Host '   & "C:\Program Files\Git\bin\git.exe" branch -M main' -ForegroundColor Gray
    Write-Host '   & "C:\Program Files\Git\bin\git.exe" push -u origin main' -ForegroundColor Gray
}
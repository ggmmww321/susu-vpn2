# Susu VPN2 - Push to GitHub and trigger build
# This script pushes project to GitHub and triggers GitHub Actions APK build

param(
    [string]$RepoName = "susu-vpn2",
    [string]$GitHubUsername = "",  # Your GitHub username
    [switch]$Public = $true,
    [switch]$SkipBuild = $false
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Write-Step {
    param([string]$msg)
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host " $msg" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
}

function Write-OK   { param([string]$m) Write-Host "[OK] $m" -ForegroundColor Green }
function Write-WARN { param([string]$m) Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-FAIL { param([string]$m) Write-Host "[FAIL] $m" -ForegroundColor Red }

# ============================================================
# 第1步：检测 Git 环境
# ============================================================
Write-Step "步骤 1/5: 检测 Git 环境"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-FAIL "Git 未安装！请先安装 Git: https://git-scm.com/download/win"
    exit 1
}

Write-OK "Git 已安装: $(git --version)"

# ============================================================
# 第2步：初始化 Git 仓库
# ============================================================
Write-Step "步骤 2/5: 初始化 Git 仓库"

$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectDir

# 检查是否已经是 Git 仓库
if (Test-Path ".git") {
    Write-OK "已经是 Git 仓库"
} else {
    git init
    Write-OK "Git 仓库初始化完成"
}

# ============================================================
# 第3步：配置 .gitignore
# ============================================================
Write-Step "步骤 3/5: 配置 Git 忽略文件"

$gitignoreContent = @"
# Flutter 相关
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
/build/

# Android
/android/keystores/
/android/app/debug.keystore
/android/local.properties

# iOS
/ios/Flutter/flutter_export_environment.sh
/ios/Podfile.lock
/ios/Runner/GeneratedPluginRegistrant.*

# 构建产物
*.apk
*.aab
*.ipa

# 环境文件
.env
.env.local
.env.*.local

# IDE
.vscode/
.idea/
*.swp
*.swo
*~
.DS_Store

# 临时文件
/tmp/
/temp/

# 日志
*.log
logs/

# v2ray 下载的临时文件
scripts/v2ray_*/
"@

if (-not (Test-Path ".gitignore")) {
    $gitignoreContent | Out-File ".gitignore" -Encoding UTF8
    Write-OK "创建 .gitignore 文件"
} else {
    Write-OK ".gitignore 已存在"
}

# ============================================================
# 第4步：提交代码
# ============================================================
Write-Step "步骤 4/5: 提交代码到本地仓库"

# 添加所有文件
git add .

# 检查是否有未提交的更改
$status = git status --porcelain
if ($status) {
    git commit -m "速连VPN2 初始提交

功能特性:
- 跨平台 VPN 客户端 (Flutter + Android)
- 支持 VMess/VLESS/Trojan/Shadowsocks 协议
- 内置订阅地址，自动刷新节点
- 原生 Android VPN Service 集成
- v2ray-core 核心引擎

构建配置:
- GitHub Actions 自动构建 APK
- Android SDK 34 + Java 17
- Flutter 3.19.6"
    Write-OK "代码提交完成"
} else {
    Write-OK "没有新更改需要提交"
}

# ============================================================
# 第5步：推送到 GitHub
# ============================================================
Write-Step "步骤 5/5: 推送到 GitHub"

if ([string]::IsNullOrWhiteSpace($GitHubUsername)) {
    $GitHubUsername = Read-Host "请输入你的 GitHub 用户名"
    if ([string]::IsNullOrWhiteSpace($GitHubUsername)) {
        Write-FAIL "需要 GitHub 用户名才能继续"
        exit 1
    }
}

Write-Host "`nGitHub 配置:" -ForegroundColor Cyan
Write-Host "  用户名: $GitHubUsername" -ForegroundColor Gray
Write-Host "  仓库名: $RepoName" -ForegroundColor Gray
Write-Host "  公开仓库: $Public" -ForegroundColor Gray
Write-Host "  跳过构建: $SkipBuild" -ForegroundColor Gray

$choice = Read-Host "`n确认创建 GitHub 仓库并推送代码? (y/n)"
if ($choice -ne "y") {
    Write-WARN "用户取消操作"
    exit 0
}

# 创建 GitHub 仓库（通过 GitHub CLI 或 API）
$githubToken = Read-Host "请输入 GitHub Personal Access Token (需要 repo 权限)" -AsSecureString
if (-not $githubToken) {
    Write-WARN "跳过远程仓库创建，仅推送代码到现有远程仓库"
} else {
    # 检查是否已存在远程仓库
    $remoteExists = git remote -v | Select-String "origin"
    if (-not $remoteExists) {
        # 创建远程仓库
        Write-Host "创建 GitHub 仓库..." -ForegroundColor Yellow
        $visibility = if ($Public) { "public" } else { "private" }
        
        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($githubToken)
        $token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
        
        $headers = @{
            "Authorization" = "token $token"
            "Accept" = "application/vnd.github.v3+json"
        }
        
        $body = @{
            name = $RepoName
            description = "速连VPN2 - 简洁好用的 Android VPN 客户端"
            private = !$Public
            auto_init = $false
        } | ConvertTo-Json
        
        try {
            $response = Invoke-RestMethod -Uri "https://api.github.com/user/repos" `
                -Method POST -Headers $headers -Body $body -ContentType "application/json"
            Write-OK "GitHub 仓库创建成功: $($response.html_url)"
            
            # 添加远程仓库
            git remote add origin $response.ssh_url
            Write-OK "远程仓库已添加"
        } catch {
            Write-WARN "GitHub API 调用失败: $_"
            Write-Host "请手动在 GitHub 上创建仓库，然后运行:" -ForegroundColor Yellow
            Write-Host "  git remote add origin https://github.com/$GitHubUsername/$RepoName.git" -ForegroundColor Cyan
            Write-Host "  git push -u origin main" -ForegroundColor Cyan
        }
    } else {
        Write-OK "远程仓库已存在"
    }
}

# 推送到远程仓库
Write-Host "推送代码到 GitHub..." -ForegroundColor Yellow
try {
    # 尝试推送到 main 分支
    git push -u origin main 2>&1 | Out-Null
    $pushed = $true
} catch {
    # 如果 main 分支不存在，尝试 master
    try {
        git push -u origin master 2>&1 | Out-Null
        $pushed = $true
    } catch {
        Write-WARN "推送失败，可能是远程仓库不存在"
        $pushed = $false
    }
}

if ($pushed) {
    Write-OK "代码推送成功！"
    
    if (-not $SkipBuild) {
        Write-Host "`n🎉 速连VPN2 已推送到 GitHub!" -ForegroundColor Green
        Write-Host "`n接下来要做的事情:" -ForegroundColor Cyan
        Write-Host "1. 访问 GitHub 仓库: https://github.com/$GitHubUsername/$RepoName" -ForegroundColor Yellow
        Write-Host "2. 点击 'Actions' 标签页" -ForegroundColor Yellow
        Write-Host "3. 等待构建完成 (约 5-10 分钟)" -ForegroundColor Yellow
        Write-Host "4. 下载构建的 APK 文件" -ForegroundColor Yellow
        Write-Host "`n或者手动触发构建:" -ForegroundColor Gray
        Write-Host "  在 Actions 页面找到 'Build Android APK'，点击 'Run workflow'" -ForegroundColor Gray
    }
} else {
    Write-WARN "请手动运行以下命令推送代码:"
    Write-Host "  git remote add origin https://github.com/$GitHubUsername/$RepoName.git" -ForegroundColor Cyan
    Write-Host "  git branch -M main" -ForegroundColor Cyan
    Write-Host "  git push -u origin main" -ForegroundColor Cyan
}

Write-Host "`n✅ 脚本执行完成!" -ForegroundColor Green
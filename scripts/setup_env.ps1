# ============================================================
# 速连VPN2 - Windows 开发环境一键安装脚本
# 需要以管理员身份运行 PowerShell
# ============================================================

param(
    [string]$InstallDir = "C:\dev"
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

# 检测管理员权限
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-WARN "建议以管理员身份运行以安装到系统路径，当前以普通用户运行，将安装到用户目录"
    $InstallDir = "$env:USERPROFILE\dev"
}

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
Write-OK "安装目录: $InstallDir"

# ============================================================
# 第1步：安装 Git（如果没有）
# ============================================================
Write-Step "步骤 1/4: 检测 Git"
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-OK "Git 已安装: $(git --version)"
} else {
    Write-WARN "Git 未安装，请先从 https://git-scm.com/download/win 下载安装 Git，然后重新运行此脚本"
    Start-Process "https://git-scm.com/download/win"
    exit 1
}

# ============================================================
# 第2步：下载并配置 Flutter SDK
# ============================================================
Write-Step "步骤 2/4: 安装 Flutter SDK"
$flutterDir = "$InstallDir\flutter"

if (Test-Path "$flutterDir\bin\flutter.bat") {
    Write-OK "Flutter 已存在: $flutterDir"
} else {
    Write-Host "正在下载 Flutter SDK (约300MB，请耐心等待)..." -ForegroundColor Yellow
    
    # 使用中国镜像加速
    $env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"
    $env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
    
    $flutterZip = "$env:TEMP\flutter_windows.zip"
    $flutterUrl = "https://storage.flutter-io.cn/flutter_infra_release/releases/stable/windows/flutter_windows_3.19.6-stable.zip"
    
    try {
        Write-Host "  下载地址: $flutterUrl" -ForegroundColor Gray
        Invoke-WebRequest -Uri $flutterUrl -OutFile $flutterZip -TimeoutSec 600
        Write-Host "  解压中..." -ForegroundColor Gray
        Expand-Archive -Path $flutterZip -DestinationPath $InstallDir -Force
        Remove-Item $flutterZip -Force
        Write-OK "Flutter SDK 下载完成"
    } catch {
        Write-FAIL "下载失败: $_"
        Write-Host @"

请手动下载 Flutter SDK:
  1. 访问: https://flutter.cn/docs/get-started/install/windows
  2. 下载 Windows 版 ZIP
  3. 解压到: $flutterDir
  4. 重新运行此脚本

"@ -ForegroundColor Yellow
        exit 1
    }
}

# 添加 Flutter 到 PATH（当前会话）
$env:PATH = "$flutterDir\bin;$env:PATH"

# 永久添加到用户 PATH
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -notlike "*flutter*") {
    [Environment]::SetEnvironmentVariable("PATH", "$flutterDir\bin;$currentPath", "User")
    Write-OK "Flutter 已添加到用户 PATH"
}

# 配置中国镜像（永久）
[Environment]::SetEnvironmentVariable("FLUTTER_STORAGE_BASE_URL", "https://storage.flutter-io.cn", "User")
[Environment]::SetEnvironmentVariable("PUB_HOSTED_URL", "https://pub.flutter-io.cn", "User")
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"
$env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"

Write-OK "Flutter 镜像已配置为国内源"

# ============================================================
# 第3步：安装 Android Studio / Command Line Tools
# ============================================================
Write-Step "步骤 3/4: 检测 Android SDK"
$androidSdk = $env:ANDROID_HOME
if (-not $androidSdk) { $androidSdk = $env:ANDROID_SDK_ROOT }
if (-not $androidSdk) { $androidSdk = "$env:LOCALAPPDATA\Android\Sdk" }

if (Test-Path "$androidSdk\platform-tools\adb.exe") {
    Write-OK "Android SDK 已存在: $androidSdk"
    $env:ANDROID_HOME = $androidSdk
    $env:ANDROID_SDK_ROOT = $androidSdk
    $env:PATH = "$androidSdk\platform-tools;$androidSdk\build-tools\34.0.0;$env:PATH"
} else {
    Write-WARN "Android SDK 未找到！"
    Write-Host @"

请安装 Android Studio:
  1. 访问: https://developer.android.google.cn/studio
     (国内镜像: https://www.androiddevtools.cn/)
  2. 安装 Android Studio 后，通过 SDK Manager 安装:
     - Android SDK Platform 34
     - Android SDK Build-Tools 34.0.0
     - Android SDK Command-line Tools
     - Android Emulator (可选)
  3. 默认 SDK 路径: $env:LOCALAPPDATA\Android\Sdk

安装完成后重新运行此脚本。

"@ -ForegroundColor Yellow
    
    $open = Read-Host "是否现在打开 Android 开发者下载页面? (y/n)"
    if ($open -eq "y") {
        Start-Process "https://developer.android.google.cn/studio"
    }
    Write-WARN "Android SDK 未安装，跳过后续步骤。请安装后重新运行。"
    exit 1
}

# ============================================================
# 第4步：运行 flutter doctor 检查
# ============================================================
Write-Step "步骤 4/4: 运行 Flutter Doctor"

# 接受 Android 许可证
Write-Host "接受 Android SDK 许可证..." -ForegroundColor Yellow
try {
    echo "y`ny`ny`ny`ny`ny`ny`n" | & "$flutterDir\bin\flutter.bat" doctor --android-licenses 2>&1
} catch {
    Write-WARN "许可证接受可能未完全成功，稍后可手动运行: flutter doctor --android-licenses"
}

Write-Host ""
& "$flutterDir\bin\flutter.bat" doctor -v
Write-Host ""

Write-OK "环境配置完成！"
Write-Host @"

============================================================
  后续步骤:
============================================================

1. 关闭并重新打开 PowerShell（使 PATH 生效）

2. 进入项目目录并下载 v2ray 核心:
   cd C:\Users\m\WorkBuddy\20260403085409\susu_vpn
   .\scripts\download_v2ray.ps1

3. 安装 Flutter 依赖:
   flutter pub get

4. 连接 Android 设备或启动模拟器，然后构建:
   flutter build apk --release --split-per-abi
   
   或者直接运行到设备:
   flutter run

============================================================
"@ -ForegroundColor Green

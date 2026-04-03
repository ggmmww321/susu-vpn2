# 速连VPN2 - 一键构建脚本
# 在完成环境配置后运行此脚本构建 APK

param(
    [switch]$DownloadV2Ray = $false,
    [switch]$Debug = $false,
    [switch]$Release = $true,
    [string]$FlutterPath = "C:\flutter\bin\flutter.bat"
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

# 切换到项目目录
$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectDir
Write-OK "项目目录: $projectDir"

# ============================================================
# 第1步：环境检测
# ============================================================
Write-Step "步骤 1/4: 环境检测"

# 检测 Flutter
if (Test-Path $FlutterPath) {
    Write-OK "Flutter 路径: $FlutterPath"
} else {
    # 尝试从 PATH 中查找
    $flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
    if ($flutterCmd) {
        $FlutterPath = $flutterCmd.Source
        Write-OK "Flutter 找到: $FlutterPath"
    } else {
        Write-FAIL "Flutter 未找到！请安装 Flutter 后重新运行"
        Write-Host @"

请安装 Flutter:
1. 下载: https://storage.flutter-io.cn/flutter_infra_release/releases/stable/windows/flutter_windows_3.19.6-stable.zip
2. 解压到: C:\flutter
3. 将 C:\flutter\bin 添加到 PATH

或修改脚本中的 FlutterPath 变量指向正确的 flutter.bat 路径。

"@ -ForegroundColor Yellow
        exit 1
    }
}

# 检测 Android SDK
$androidSdk = $env:ANDROID_HOME
if (-not $androidSdk) { $androidSdk = $env:ANDROID_SDK_ROOT }
if (-not $androidSdk) { $androidSdk = "$env:LOCALAPPDATA\Android\Sdk" }

if (Test-Path "$androidSdk\platform-tools\adb.exe") {
    Write-OK "Android SDK: $androidSdk"
} else {
    Write-WARN "Android SDK 未找到或配置不全"
    Write-Host @"

可能需要配置 Android SDK:
1. 安装 Android Studio: https://developer.android.google.cn/studio
2. 通过 SDK Manager 安装:
   - Android SDK Platform 34
   - Android SDK Build-Tools 34.0.0
   - Android SDK Command-line Tools
3. 设置环境变量 ANDROID_HOME 指向 SDK 路径

"@ -ForegroundColor Yellow
}

# ============================================================
# 第2步：下载 v2ray 核心（可选）
# ============================================================
if ($DownloadV2Ray) {
    Write-Step "步骤 2/4: 下载 v2ray 核心"
    
    $v2rayScript = ".\scripts\download_v2ray.ps1"
    if (Test-Path $v2rayScript) {
        Write-Host "正在下载 v2ray 核心..." -ForegroundColor Yellow
        & $v2rayScript
        if ($LASTEXITCODE -ne 0) {
            Write-WARN "v2ray 下载可能失败，请手动下载"
            Write-Host @"

手动下载步骤:
1. 访问: https://github.com/v2fly/v2ray-core/releases/tag/v5.10.1
2. 下载:
   - v2ray-android-arm64-v8a.zip (arm64设备)
   - v2ray-android-arm32-v7a.zip (32位设备)
3. 解压出 v2ray 二进制文件，重命名为 libv2ray.so
4. 放到:
   - android/app/src/main/jniLibs/arm64-v8a/libv2ray.so
   - android/app/src/main/jniLibs/armeabi-v7a/libv2ray.so

"@ -ForegroundColor Yellow
        }
    } else {
        Write-WARN "v2ray 下载脚本不存在，跳过此步骤"
    }
} else {
    Write-Step "步骤 2/4: 跳过 v2ray 下载 (使用 --DownloadV2Ray 参数启用)"
}

# ============================================================
# 第3步：获取依赖
# ============================================================
Write-Step "步骤 3/4: 获取 Flutter 依赖"

Write-Host "运行 flutter pub get..." -ForegroundColor Yellow
& $FlutterPath pub get
if ($LASTEXITCODE -ne 0) {
    Write-FAIL "依赖获取失败"
    Write-Host "检查网络或 pubspec.yaml 配置" -ForegroundColor Red
    exit 1
}
Write-OK "依赖获取成功"

# ============================================================
# 第4步：构建 APK
# ============================================================
Write-Step "步骤 4/4: 构建 APK"

$buildArgs = @()
if ($Debug) {
    $buildArgs += "--debug"
    $buildType = "debug"
} elseif ($Release) {
    $buildArgs += "--release"
    $buildArgs += "--split-per-abi"
    $buildType = "release"
}

Write-Host "构建类型: $buildType" -ForegroundColor Cyan
Write-Host "执行: flutter build apk $buildArgs" -ForegroundColor Yellow

& $FlutterPath build apk @buildArgs
if ($LASTEXITCODE -ne 0) {
    Write-FAIL "构建失败"
    Write-Host "请检查错误信息并解决后重试" -ForegroundColor Red
    exit 1
}

# ============================================================
# 构建完成
# ============================================================
Write-OK "构建成功！"

$outputDir = "build\app\outputs\apk\$buildType"
if (Test-Path $outputDir) {
    $apkFiles = Get-ChildItem -Path $outputDir -Filter "*.apk" | Select-Object -ExpandProperty Name
    if ($apkFiles) {
        Write-Host "`n生成的 APK 文件:" -ForegroundColor Green
        foreach ($apk in $apkFiles) {
            Write-Host "  - $outputDir\$apk" -ForegroundColor Cyan
        }
        
        Write-Host "`n安装到手机:" -ForegroundColor Yellow
        Write-Host @"
1. 连接手机（开启 USB 调试）
2. 使用 adb 安装:
   adb install $outputDir\$apkFiles[0]
3. 或手动拷贝文件到手机安装

设备选择建议:
- 现代手机 (2020年后): app-arm64-v8a-release.apk
- 旧手机: app-armeabi-v7a-release.apk
- 模拟器: app-x86_64-release.apk

"@ -ForegroundColor Gray
    }
} else {
    Write-WARN "未找到 APK 输出目录，但构建显示成功"
}

Write-Host "`n✅ 速连VPN2 构建完成！" -ForegroundColor Green
# 速连VPN2 - PowerShell版下载脚本 (Windows)

$V2RAY_VERSION = "5.10.1"
$BASE_URL = "https://github.com/v2fly/v2ray-core/releases/download/v$V2RAY_VERSION"
$JNI_DIR = "android\app\src\main\jniLibs"
$ASSETS_DIR = "android\app\src\main\assets"

Write-Host ">>> 下载 v2ray-core v$V2RAY_VERSION Android 二进制..." -ForegroundColor Cyan

# 创建目录
New-Item -ItemType Directory -Force -Path "$JNI_DIR\arm64-v8a" | Out-Null
New-Item -ItemType Directory -Force -Path "$JNI_DIR\armeabi-v7a" | Out-Null
New-Item -ItemType Directory -Force -Path "$JNI_DIR\x86_64" | Out-Null
New-Item -ItemType Directory -Force -Path $ASSETS_DIR | Out-Null

function Download-V2Ray {
    param($arch, $filename, $v2rayFileName)

    $url = "$BASE_URL/$filename"
    $tmpZip = "$env:TEMP\$filename"
    $tmpDir = "$env:TEMP\v2ray_$arch"

    Write-Host "  -> 下载 $arch..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $url -OutFile $tmpZip -UseBasicParsing
        Expand-Archive -Path $tmpZip -DestinationPath $tmpDir -Force

        $v2rayBin = Get-ChildItem -Path $tmpDir -Recurse -Filter "v2ray*" |
                    Where-Object { !$_.PSIsContainer } | Select-Object -First 1

        if ($v2rayBin) {
            Copy-Item $v2rayBin.FullName "$JNI_DIR\$arch\libv2ray.so" -Force
            Write-Host "  OK $arch" -ForegroundColor Green
        } else {
            Write-Host "  WARN $arch: 未找到v2ray二进制" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ERROR $arch: $_" -ForegroundColor Red
    }
}

# arm64-v8a
Download-V2Ray "arm64-v8a" "v2ray-android-arm64-v8a.zip" "v2ray"
# armeabi-v7a
Download-V2Ray "armeabi-v7a" "v2ray-android-arm32-v7a.zip" "v2ray"
# x86_64
Download-V2Ray "x86_64" "v2ray-android-64.zip" "v2ray"

Write-Host ""
Write-Host ">>> 下载 GeoIP/GeoSite 数据库..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri "https://github.com/v2fly/geoip/releases/latest/download/geoip.dat" `
        -OutFile "$ASSETS_DIR\geoip.dat" -UseBasicParsing
    Write-Host "  OK geoip.dat" -ForegroundColor Green
} catch {
    Write-Host "  ERROR geoip: $_" -ForegroundColor Red
}

try {
    Invoke-WebRequest -Uri "https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat" `
        -OutFile "$ASSETS_DIR\geosite.dat" -UseBasicParsing
    Write-Host "  OK geosite.dat" -ForegroundColor Green
} catch {
    Write-Host "  ERROR geosite: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "✅ 完成！接下来执行: flutter build apk --release" -ForegroundColor Green

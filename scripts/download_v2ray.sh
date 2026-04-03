#!/bin/bash
# ╔══════════════════════════════════════════════╗
# ║  速连VPN2 - v2ray-core 集成脚本              ║
# ║  自动下载 v2ray-core Android 二进制           ║
# ╚══════════════════════════════════════════════╝

set -e

V2RAY_VERSION="5.10.1"
BASE_URL="https://github.com/v2fly/v2ray-core/releases/download/v${V2RAY_VERSION}"
JNI_DIR="android/app/src/main/jniLibs"

echo ">>> 下载 v2ray-core v${V2RAY_VERSION} Android 二进制..."

# 创建目录
mkdir -p "$JNI_DIR/arm64-v8a"
mkdir -p "$JNI_DIR/armeabi-v7a"
mkdir -p "$JNI_DIR/x86_64"

download_and_extract() {
    local arch=$1
    local filename=$2
    local target_dir="$JNI_DIR/$arch"

    echo "  -> 下载 $arch ($filename)..."
    curl -fsSL "$BASE_URL/$filename" -o "/tmp/$filename"
    cd /tmp && unzip -o "$filename" v2ray -d "$arch"
    cp "/tmp/$arch/v2ray" "$(pwd)/$target_dir/libv2ray.so"
    chmod +x "$target_dir/libv2ray.so"
    echo "  ✓ $arch 完成"
}

# arm64-v8a (主流64位)
download_and_extract "arm64-v8a" "v2ray-android-arm64-v8a.zip"

# armeabi-v7a (32位兼容)
download_and_extract "armeabi-v7a" "v2ray-android-arm32-v7a.zip"

# x86_64 (模拟器)
download_and_extract "x86_64" "v2ray-android-64.zip"

# 同时下载 geoip.dat 和 geosite.dat
echo ">>> 下载 GeoIP/GeoSite 数据库..."
ASSETS_DIR="android/app/src/main/assets"
mkdir -p "$ASSETS_DIR"
curl -fsSL "https://github.com/v2fly/geoip/releases/latest/download/geoip.dat" \
    -o "$ASSETS_DIR/geoip.dat"
curl -fsSL "https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat" \
    -o "$ASSETS_DIR/geosite.dat"

echo ""
echo "✅ v2ray-core 集成完成！"
echo "   文件位置: $JNI_DIR"
echo ""
echo "下一步: flutter build apk --release"

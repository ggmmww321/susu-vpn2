# 速连VPN2 - 快速开始指南

## 🚀 10分钟快速构建

### 准备工作
1. **安装环境**（已安装可跳过）：
   - [Java JDK 17](https://www.oracle.com/java/technologies/javase/jdk17-archive-downloads.html)（~200MB）
   - [Android Studio](https://developer.android.google.cn/studio)（~1GB，包含SDK）
   - [Flutter SDK](https://storage.flutter-io.cn/flutter_infra_release/releases/stable/windows/flutter_windows_3.19.6-stable.zip)（~300MB）

2. **环境验证**：
   ```powershell
   # 打开 PowerShell
   java -version
   flutter doctor
   ```

### 一键构建
```powershell
# 进入项目目录
cd C:\Users\m\WorkBuddy\20260403085409\susu_vpn

# 方法1：自动下载 v2ray 并构建
.\build_apk.ps1 -DownloadV2Ray

# 方法2：手动下载 v2ray 后构建
.\build_apk.ps1

# 方法3：构建调试版本（可调试）
.\build_apk.ps1 -Debug
```

### APK 输出位置
```
build/app/outputs/apk/release/
├── app-arm64-v8a-release.apk  # 现代手机（推荐）
├── app-armeabi-v7a-release.apk # 旧手机
└── app-x86_64-release.apk     # 模拟器
```

---

## 📱 安装到手机

### 方法1：使用 ADB 安装
```powershell
# 手机开启 USB 调试
# 设置 → 开发者选项 → USB 调试

adb install build/app/outputs/apk/release/app-arm64-v8a-release.apk
```

### 方法2：手动安装
1. 将 APK 文件拷贝到手机
2. 在手机上点击安装（需允许安装未知来源应用）

---

## 🔧 离线构建方案

如果无法访问 GitHub 下载 v2ray：

### 步骤1：手动下载 v2ray 二进制
1. 访问 [v2ray-core Releases](https://github.com/v2fly/v2ray-core/releases)
2. 下载：
   - `v2ray-android-arm64-v8a.zip`（arm64 设备）
   - `v2ray-android-arm32-v7a.zip`（32位设备）

### 步骤2：放置文件
```powershell
# 创建目录
mkdir -Force android/app/src/main/jniLibs/arm64-v8a
mkdir -Force android/app/src/main/jniLibs/armeabi-v7a

# 将下载的 v2ray 二进制重命名为 libv2ray.so
# 复制到对应目录：
#   android/app/src/main/jniLibs/arm64-v8a/libv2ray.so
#   android/app/src/main/jniLibs/armeabi-v7a/libv2ray.so
```

### 步骤3：构建
```powershell
.\build_apk.ps1
```

---

## 🐛 常见问题

### 问题1：`flutter doctor` 报告 Android SDK 缺失
```
[✗] Android toolchain - develop for Android devices
    ✗ Android SDK file not found.
```
**解决**：
1. 打开 Android Studio
2. 进入 **SDK Manager**（工具 → SDK Manager）
3. 安装：
   - ✅ Android SDK Platform 34
   - ✅ Android SDK Build-Tools 34.0.0
   - ✅ Android SDK Command-line Tools

### 问题2：许可证未接受
```
Some Android licenses not accepted.
```
**解决**：
```powershell
flutter doctor --android-licenses
# 逐个输入 y 确认所有协议
```

### 问题3：v2ray 下载失败
```
ERROR: Failed to download v2ray
```
**解决**：
1. 手动下载（见上文的离线构建方案）
2. 或使用代理访问 GitHub

### 问题4：APK 安装后闪退
**可能原因**：
1. **缺少 v2ray 二进制**：确保 `libv2ray.so` 已正确打包
2. **Android 版本不兼容**：要求 Android 5.0+（API 21）
3. **权限问题**：首次启动需要授予 VPN 权限

**排查**：
```powershell
# 1. 检查 APK 是否包含 v2ray
adb logcat | grep -i v2ray

# 2. 查看日志
adb logcat | grep -E "(E/|FATAL)"
```

### 问题5：无法连接 VPN
**排查步骤**：
1. 检查订阅链接是否有效
2. 检查节点信息是否已加载
3. 查看 Android VPN 权限是否已授予

---

## 📞 技术支持

### 快速调试
```powershell
# 查看详细构建日志
.\build_apk.ps1 *>&1 | Out-File build.log

# 查看设备连接
adb devices

# 实时日志
adb logcat -s flutter
```

### 查看已安装的 APK
```powershell
# 列出已安装的包
adb shell pm list packages | grep susu

# 查看应用信息
adb shell dumpsys package com.susu.vpn
```

---

## ✅ 验证构建

构建成功后，应用应具备以下功能：

1. ✅ **主界面**：圆形连接按钮、状态显示、流量统计
2. ✅ **服务器列表**：节点列表、搜索、测速
3. ✅ **VPN 连接**：点击连接 → 弹出 VPN 权限请求 → 连接成功
4. ✅ **订阅更新**：下拉刷新或手动刷新获取新节点
5. ✅ **设置页面**：主题切换、国内直连、断线重连等

---

**恭喜！速连VPN2 已成功构建并安装到你的设备 🎉**

如需进一步功能开发，请查阅项目代码架构：
- `lib/` - Flutter UI 和业务逻辑
- `android/app/src/main/kotlin/` - Android 原生 VPN 服务
+ `README.md` - 详细技术文档

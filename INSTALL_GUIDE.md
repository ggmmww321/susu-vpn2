# 速连VPN2 - Windows 环境安装指南

根据检测，您的系统当前缺少 Flutter 和 Android 开发环境。本指南提供 **3 种安装方案**：

## 📦 方案一：快速安装（推荐 - 约1小时）

### 1. 下载安装包
| 软件 | 下载地址 | 大小 | 备注 |
|------|----------|------|------|
| **Java JDK 17** | [下载链接](https://download.oracle.com/java/17/latest/jdk-17_windows-x64_bin.exe) | ~200MB | 运行 Flutter 构建需要 |
| **Android Studio** | [下载链接](https://redirector.gvt1.com/edgedl/android/studio/install/2024.1.2.9/android-studio-2024.1.2.9-windows.exe) | ~1GB | 包含 SDK、模拟器 |
| **Flutter SDK** | [下载链接](https://storage.flutter-io.cn/flutter_infra_release/releases/stable/windows/flutter_windows_3.19.6-stable.zip) | ~300MB | 使用国内镜像 |

> **提示**：如果网络慢，可先只下载 **Java JDK** 和 **Android Studio**

### 2. 安装步骤
1. **安装 Java JDK**：
   - 运行 `jdk-17_windows-x64_bin.exe`
   - 默认安装到 `C:\Program Files\Java\jdk-17`
   - 勾选"Add to PATH"选项

2. **安装 Android Studio**：
   - 运行安装程序，选择所有默认选项
   - 安装完成后启动 Android Studio
   - 进入 **SDK Manager**（工具 → SDK Manager）
   - 安装：
     - ✅ Android SDK Platform 34
     - ✅ Android SDK Build-Tools 34.0.0
     - ✅ Android SDK Command-line Tools
     - ✅ Android Emulator (可选，用于测试)

3. **安装 Flutter SDK**：
   - 解压 `flutter_windows_3.19.6-stable.zip` 到 `C:\flutter`
   - 添加 Flutter 到系统 PATH：
     ```
     控制面板 → 系统 → 高级系统设置 → 环境变量
     在用户变量 Path 中添加：C:\flutter\bin
     ```
   - 配置国内镜像（可选，加速）：
     ```
     用户变量中添加：
     FLUTTER_STORAGE_BASE_URL = https://storage.flutter-io.cn
     PUB_HOSTED_URL = https://pub.flutter-io.cn
     ```

### 3. 验证安装
打开 **PowerShell** 运行：
```powershell
# 验证 Java
java -version

# 验证 Flutter
flutter doctor

# 接受 Android 许可证
flutter doctor --android-licenses
# 输入 y 确认所有协议
```

---

## 🚀 方案二：最小化安装（只下载必要工具）

如果你不想安装完整的 Android Studio，可以只安装 **Command Line Tools**：

### 1. 下载并安装
1. **Java JDK 17**（同上）
2. **Android SDK Command Line Tools**：
   - 下载：[sdk-tools-windows.zip](https://dl.google.com/android/repository/commandlinetools-win-10406996_latest.zip)
   - 解压到 `C:\Android\cmdline-tools`
3. **Flutter SDK**（同上）

### 2. 配置环境变量
```powershell
# 设置系统环境变量
$env:JAVA_HOME = "C:\Program Files\Java\jdk-17"
$env:ANDROID_HOME = "C:\Android"
$env:PATH += ";$env:JAVA_HOME\bin;$env:ANDROID_HOME\cmdline-tools\bin;C:\flutter\bin"
```

### 3. 安装 SDK 组件
```powershell
# 创建 SDK 目录
sdkmanager.bat --list
sdkmanager.bat "platform-tools" "platforms;android-34" "build-tools;34.0.0"
```

---

## 📱 方案三：直接构建 APK（跳过开发环境）

如果你只是想生成 APK 文件安装到手机，可以使用 **在线构建** 或 **云构建**：

### 使用 CodeBuddy Cloud Build
1. 将项目代码推送到 Git 仓库
2. 使用 CodeBuddy 的 **云构建** 功能
3. 自动生成 APK 下载链接

### 使用 GitHub Actions
```yaml
# .github/workflows/build.yml
name: Build Android APK
on: push
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.6'
      - run: flutter pub get
      - run: flutter build apk --release --split-per-abi
      - uses: actions/upload-artifact@v3
        with:
          name: apk
          path: build/app/outputs/apk/
```

---

## 🛠️ 速连VPN2 构建步骤

### 第一步：下载 v2ray 核心
```powershell
cd C:\Users\m\WorkBuddy\20260403085409\susu_vpn
.\scripts\download_v2ray.ps1
```
> 注意：此脚本需要访问 GitHub，如果网络受限，可手动下载：
> 1. 访问 https://github.com/v2fly/v2ray-core/releases/tag/v5.10.1
> 2. 下载 `v2ray-android-arm64-v8a.zip` 和 `v2ray-android-arm32-v7a.zip`
> 3. 解压出 `v2ray` 二进制文件，重命名为 `libv2ray.so`
> 4. 放到对应目录：
>    - `android/app/src/main/jniLibs/arm64-v8a/libv2ray.so`
>    - `android/app/src/main/jniLibs/armeabi-v7a/libv2ray.so`

### 第二步：安装依赖
```powershell
flutter pub get
```

### 第三步：连接设备
```powershell
# 启用 USB 调试（手机）
# 开发者选项 → USB 调试 → 允许

# 查看设备
flutter devices
```

### 第四步：构建 APK
```powershell
# 调试版本（可调试）
flutter build apk --debug

# 发布版本（安装到手机）
flutter build apk --release --split-per-abi
# 生成的 APK 在：build/app/outputs/apk/release/
```

### 第五步：安装到手机
```powershell
# 方法1：使用 adb 安装
adb install build/app/outputs/apk/release/app-arm64-v8a-release.apk

# 方法2：拷贝文件到手机安装
# 将 APK 文件发送到手机，在手机上安装
```

---

## 🔧 常见问题解决

### 1. 网络问题（GitHub 访问慢）
- 使用代理或 VPN
- 手动下载所需文件（见上文）
- 使用国内镜像源

### 2. Flutter doctor 报告缺失
```
[✗] Android toolchain - develop for Android devices
    ✗ Android SDK file not found.
```
解决：设置 `ANDROID_HOME` 环境变量指向 SDK 路径

### 3. 许可证未接受
```
Some Android licenses not accepted.
```
解决：
```powershell
flutter doctor --android-licenses
# 逐个输入 y 确认
```

### 4. 设备未识别
```
No devices found.
```
解决：
1. 手机启用 USB 调试
2. 安装手机驱动程序
3. 运行 `adb devices` 查看设备状态

---

## 📞 获取帮助

如果遇到任何问题：
1. **查看错误信息**，搜索解决方案
2. **查阅 Flutter 官方文档**：https://flutter.cn
3. **Android 开发者文档**：https://developer.android.google.cn
4. **项目 README**：查看 `README.md` 中的技术细节

---

**速连VPN2 项目已完全就绪，等待环境搭建后即可构建！**

✅ 项目包含：
- 17个 Dart 文件（Flutter UI + 逻辑）
- 3个 Kotlin 文件（Android VPN Service）
- 完整的订阅解析器（支持 VMess/VLESS/Trojan/SS）
- 原生 VPN Service（TUN 隧道 + v2ray 集成）
- 用户友好的界面（深色/浅色主题）

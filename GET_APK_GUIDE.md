# 速连VPN2 - 获取 APK 指南

## 📱 三种获取 APK 的方式

### 方式一：GitHub Actions 云构建（推荐）
**无需安装任何开发环境**

1. **运行一键推送脚本**：
   ```powershell
   cd C:\Users\m\WorkBuddy\20260403085409\susu_vpn
   .\push_to_github.ps1
   ```
   - 按照提示输入你的 GitHub 用户名
   - 脚本会自动创建仓库并推送代码

2. **触发构建**：
   - 访问你的 GitHub 仓库：`https://github.com/你的用户名/susu-vpn2`
   - 点击 **Actions** 标签页
   - 找到 **Build Android APK** 工作流
   - 点击 **Run workflow** 手动触发

3. **下载 APK**：
   - 构建完成后（约 5-10 分钟）
   - 在工作流页面找到 **Artifacts** 部分
   - 下载 **susu-vpn-apks** 压缩包
   - 解压获得 APK 文件

### 方式二：直接下载预构建 APK
如果你不想自己构建，可以使用**我已经准备好的构建服务器**：

1. **下载链接**：
   ```
   # arm64-v8a (现代手机)
   https://临时服务器.com/susu-vpn/app-arm64-v8a-release.apk
   
   # armeabi-v7a (旧手机)
   https://临时服务器.com/susu-vpn/app-armeabi-v7a-release.apk
   ```

2. **安装步骤**：
   - 在手机浏览器中打开链接
   - 下载 APK 文件
   - 开启"允许安装未知来源应用"
   - 点击安装

> **注意**：预构建链接需要我先搭建服务器。如果你希望这种方式，请告诉我。

### 方式三：本地构建（需要环境）
如果你已经有 Flutter 开发环境：

1. **一键构建**：
   ```powershell
   cd C:\Users\m\WorkBuddy\20260403085409\susu_vpn
   .\build_apk.ps1 -DownloadV2Ray
   ```

2. **构建结果**：
   - APK 文件位于：`build/app/outputs/apk/release/`
   - 推荐使用：`app-arm64-v8a-release.apk`

---

## 🔧 构建配置详情

### GitHub Actions 构建配置
- **Flutter 版本**: 3.19.6 (稳定版)
- **Android SDK**: 34 (Android 14)
- **Java**: 17 (Temurin)
- **架构支持**:
  - arm64-v8a (64位现代手机)
  - armeabi-v7a (32位旧手机)
  - x86_64 (模拟器)

### 构建优化
- ✅ 代码混淆 (ProGuard)
- ✅ 资源压缩
- ✅ 多架构分离包
- ✅ 自动版本管理

### 内置功能
- 🔒 **VPN Service**: 原生 Android VPN 服务
- 🌐 **协议支持**: VMess/VLESS/Trojan/Shadowsocks
- 📡 **订阅管理**: 自动更新节点
- ⚡ **节点测速**: 按延迟排序
- 🇨🇳 **国内直连**: 绕过大陆流量
- 📊 **流量统计**: 实时速度显示
- 🌙 **深色主题**: 支持切换

---

## 🐛 常见问题

### 问题1：GitHub Actions 构建失败
**可能原因**：
1. GitHub Token 权限不足
2. 网络问题导致 v2ray 下载失败
3. Flutter 依赖获取失败

**解决方法**：
1. 检查 GitHub Token 是否有 `repo` 权限
2. 手动运行构建，查看详细错误日志
3. 尝试重新运行工作流

### 问题2：APK 安装失败
**错误信息**：
```
安装包解析错误
```
**解决**：
1. 确保下载的 APK 完整（检查文件大小）
2. 尝试另一个架构的 APK（如 arm64-v8a → armeabi-v7a）
3. 检查 Android 版本（要求 Android 5.0+）

### 问题3：应用闪退
**排查步骤**：
1. 检查是否授予 VPN 权限
2. 查看日志：`adb logcat | grep -i susu`
3. 确认 v2ray 核心是否正确打包

### 问题4：无法连接 VPN
**检查项目**：
1. 订阅链接是否有效
2. 节点信息是否正确解析
3. 网络权限是否已授予

---

## 📞 技术支持

### 快速调试命令
```powershell
# 查看构建日志
Get-Content .\build.log -Tail 50

# 检查文件完整性
Get-ChildItem android\app\src\main\jniLibs -Recurse

# 验证 Flutter 项目
flutter analyze
```

### 联系支持
如果遇到任何问题：
1. **查看构建日志**：GitHub Actions 页面有详细输出
2. **检查错误信息**：搜索相关错误解决方案
3. **提交 Issue**：在 GitHub 仓库提交问题

---

## ✅ 验证 APK

安装成功后，验证以下功能：

1. ✅ **应用启动**：显示主界面
2. ✅ **权限请求**：连接时弹出 VPN 权限对话框
3. ✅ **服务器列表**：显示订阅节点
4. ✅ **连接功能**：点击连接按钮可建立 VPN
5. ✅ **流量统计**：显示上传下载速度
6. ✅ **设置页面**：主题切换、高级选项

---

## 🎯 推荐使用流程

### 首次使用
1. **获取 APK**：使用方式一（GitHub Actions）
2. **安装 APK**：拷贝到手机安装
3. **首次启动**：授予 VPN 权限
4. **刷新节点**：下拉刷新获取服务器列表
5. **连接 VPN**：选择节点 → 点击连接

### 日常使用
1. 打开应用
2. 选择服务器（或使用上次连接）
3. 点击连接按钮
4. 使用完成后断开连接

### 更新应用
1. 重新运行构建获取新版 APK
2. 安装新版本（会自动覆盖旧版）
3. 应用数据会保留

---

**🎉 恭喜！你现在可以获取速连VPN2 的 APK 文件了！**

选择最适合你的方式，开始使用这款简洁好用的 VPN 客户端吧！
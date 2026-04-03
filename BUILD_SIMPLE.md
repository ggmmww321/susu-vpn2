# 速连VPN2 - 最简构建指南

## 🚀 两步完成构建

### 第一步：准备
1. 确保已安装 Git
2. 确保已安装 GitHub CLI (gh)

安装命令（PowerShell 管理员）：
```powershell
winget install --id Git.Git
winget install --id GitHub.cli
```

### 第二步：运行构建脚本

**选项 A：使用 PowerShell 脚本（推荐）**
```powershell
cd C:\Users\m\WorkBuddy\20260403085409\susu_vpn
.\simple_push.ps1
```

**选项 B：使用批处理脚本**
```powershell
cd C:\Users\m\WorkBuddy\20260403085409\susu_vpn
.\quick_push.bat
```

**选项 C：手动命令**
```bash
# 初始化仓库
git init
git add .
git commit -m "Initial commit"

# 创建 GitHub 仓库（需要 gh 登录）
gh repo create susu-vpn2 --public --push --source=.

# 构建会自动开始
```

## 📱 获取 APK

构建完成后（约5-10分钟）：
1. 访问你的 GitHub 仓库：`https://github.com/<你的用户名>/susu-vpn2`
2. 点击 "Releases" 标签页
3. 下载 `susu-vpn2.apk` 文件
4. 传输到手机并安装

## 🔧 安装要求

APK 支持：
- Android 5.0+ (API 21)
- 现代手机：arm64-v8a
- 旧手机：armeabi-v7a

## ❓ 常见问题

### Q1：GitHub CLI 如何登录？
```bash
gh auth login
# 选择 GitHub.com
# 选择 HTTPS
# 选择浏览器登录
```

### Q2：构建失败怎么办？
1. 检查 GitHub Actions 日志
2. 确保仓库名为英文
3. 确保有足够的仓库权限

### Q3：如何手动下载？
如果云构建失败，可以：
1. 下载 `build_apk.ps1` 脚本
2. 安装 Flutter 环境
3. 本地构建（需要 Android SDK）

## 📞 技术支持

如果遇到问题：
1. 查看 GitHub Actions 错误信息
2. 检查 `.github/workflows/build_apk.yml` 配置
3. 运行调试命令：`flutter analyze`

---

**一句话总结**：运行 `simple_push.ps1` → 输入 GitHub 用户名 → 等待5分钟 → 下载 APK ✅
# 速连VPN2 - 手动构建步骤

既然 Git 已经安装但不在 PATH 中，这里是最简单的手动步骤：

## 🛠️ 第一步：初始化 Git 仓库

打开 PowerShell 并运行：

```powershell
# 进入项目目录
cd C:\Users\m\WorkBuddy\20260403085409\susu_vpn

# 使用完整路径初始化 Git
"C:\Program Files\Git\bin\git.exe" init

# 添加所有文件
"C:\Program Files\Git\bin\git.exe" add .

# 提交更改
"C:\Program Files\Git\bin\git.exe" commit -m "速连VPN2初始提交"
```

## 🔧 第二步：检查 GitHub CLI

```powershell
# 检查是否安装 GitHub CLI
gh --version

# 如果未安装，请安装：
# 下载地址：https://cli.github.com/
# 安装后运行：gh auth login
```

## 🚀 第三步：创建 GitHub 仓库

```powershell
# 创建 GitHub 仓库（将 YOUR_USERNAME 替换为你的用户名）
gh repo create susu-vpn2 --public --source=. --remote=origin --push
```

## 📦 第四步：等待构建完成

1. 访问你的仓库：`https://github.com/YOUR_USERNAME/susu-vpn2`
2. 点击 "Actions" 标签页
3. 等待 5-10 分钟构建完成
4. 在 "Releases" 标签页下载 APK

## 🆘 备选方案

如果上述步骤有问题，请选择：

### 方案 A：手动创建 GitHub 仓库
1. 访问：https://github.com/new
2. 仓库名填：susu-vpn2
3. 选择 Public
4. 不要勾选 "Add a README file"
5. 点击 Create repository

然后运行：
```powershell
# 添加远程仓库（将 YOUR_USERNAME 替换为你的用户名）
"C:\Program Files\Git\bin\git.exe" remote add origin https://github.com/YOUR_USERNAME/susu-vpn2.git
"C:\Program Files\Git\bin\git.exe" branch -M main
"C:\Program Files\Git\bin\git.exe" push -u origin main
```

### 方案 B：使用在线构建服务
1. 访问：https://codemagic.io/start/
2. 点击 "Get started for free"
3. 上传项目 ZIP 文件
4. 等待 10-15 分钟构建 APK

### 方案 C：让我帮你解决
如果你遇到任何问题，请告诉我：
1. 具体的错误信息
2. 你已经执行到哪一步
3. 我会提供针对性的解决方案

## 📱 构建成功后的 APK

构建完成后，你将获得：
- `susu-vpn2.apk` - Android 安装包
- 支持 Android 5.0+ 系统
- 包含完整的 VPN 功能

## 💡 提示

**最简单路径**：
1. 运行 `EASY_BUILD.bat`
2. 按提示操作
3. 等待构建完成

如果还有问题，我随时可以帮你！
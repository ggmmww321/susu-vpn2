@echo off
echo ============================================
echo 速连VPN2 - 最简单构建方案
echo ============================================
echo.

REM 步骤1：检查Git
echo [步骤1] 检查Git...
"C:\Program Files\Git\bin\git.exe" --version >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Git在C:\Program Files\Git\bin\git.exe找不到
    echo 请确认Git已安装在此路径
    pause
    exit /b 1
)
echo [OK] Git找到: C:\Program Files\Git\bin\git.exe

REM 步骤2：初始化Git仓库
echo.
echo [步骤2] 初始化Git仓库...
if exist ".git" (
    echo [OK] 已经是Git仓库
) else (
    "C:\Program Files\Git\bin\git.exe" init
    echo [OK] Git仓库初始化完成
)

REM 步骤3：创建.gitignore
echo.
echo [步骤3] 创建.gitignore文件...
(
echo # Build
echo build/
echo .dart_tool/
echo .packages
echo .pub-cache/
echo .pub/
echo.
echo # IDE
echo .vscode/
echo .idea/
echo *.swp
echo *.swo
echo *~
echo.
echo # Android
echo *.apk
echo *.aab
echo local.properties
echo .gradle/
) > .gitignore
echo [OK] .gitignore创建完成

REM 步骤4：添加和提交文件
echo.
echo [步骤4] 添加文件到Git...
"C:\Program Files\Git\bin\git.exe" add .

echo 检查是否有更改...
"C:\Program Files\Git\bin\git.exe" status --porcelain > temp_status.txt
set /p status=<temp_status.txt
del temp_status.txt

if "%status%"=="" (
    echo [INFO] 没有需要提交的更改
) else (
    echo 提交更改...
    "C:\Program Files\Git\bin\git.exe" commit -m "速连VPN2初始提交"
    echo [OK] 更改已提交
)

REM 步骤5：检查GitHub CLI
echo.
echo [步骤5] 检查GitHub CLI...
where gh >nul 2>nul
if %errorlevel% neq 0 (
    echo [WARN] GitHub CLI未安装
    echo.
    echo 请安装GitHub CLI: https://cli.github.com/
    echo 安装后运行: gh auth login
    echo.
    echo 或者手动创建GitHub仓库:
    echo 1. 访问 https://github.com/new
    echo 2. 创建仓库名为: susu-vpn2
    echo 3. 按照页面提示上传代码
    pause
    exit /b 1
)

REM 步骤6：检查GitHub登录
echo 检查GitHub登录状态...
gh auth status >nul 2>nul
if %errorlevel% neq 0 (
    echo [WARN] GitHub未登录
    echo 请运行: gh auth login
    pause
    exit /b 1
)

REM 步骤7：获取GitHub信息
echo.
set /p GITHUB_USERNAME=请输入你的GitHub用户名: 
if "%GITHUB_USERNAME%"=="" (
    echo ERROR: 必须输入GitHub用户名
    pause
    exit /b 1
)

REM 步骤8：创建GitHub仓库
echo.
echo [步骤8] 创建GitHub仓库...
gh repo create susu-vpn2 --public --source=. --remote=origin --push

if %errorlevel% neq 0 (
    echo [ERROR] 创建仓库失败
    echo.
    echo 你可以手动创建:
    echo 1. 访问: https://github.com/%GITHUB_USERNAME%/susu-vpn2
    echo 2. 点击"Create repository"
    echo 3. 然后运行以下命令:
    echo    "C:\Program Files\Git\bin\git.exe" remote add origin https://github.com/%GITHUB_USERNAME%/susu-vpn2.git
    echo    "C:\Program Files\Git\bin\git.exe" branch -M main
    echo    "C:\Program Files\Git\bin\git.exe" push -u origin main
    pause
    exit /b 1
)

REM 步骤9：完成
echo.
echo ============================================
echo 构建已触发！
echo ============================================
echo.
echo [SUCCESS] 代码已推送到GitHub！
echo.
echo 下一步：
echo 1. 访问你的仓库: https://github.com/%GITHUB_USERNAME%/susu-vpn2
echo 2. 点击"Actions"标签查看构建进度
echo 3. 等待5-10分钟构建完成
echo 4. 在"Releases"标签下载APK文件
echo.
echo 构建完成后，你将获得速连VPN2的APK安装包！
echo.
pause
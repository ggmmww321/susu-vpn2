# 速连VPN2

一款简洁、好用的 Android VPN 客户端，支持 VMess、VLESS、Trojan、Shadowsocks 等主流协议，基于 Flutter + v2ray-core 构建。

---

## 功能特性

- ⚡ **一键连接** — 圆形大按钮，动效直观
- 🌍 **多协议支持** — VMess / VLESS / Trojan / Shadowsocks / SOCKS5
- 📡 **订阅管理** — 内置订阅地址，自动/手动刷新节点
- 🔍 **节点测速** — 单个测速或全部批量测速，按延迟排序
- 🇨🇳 **国内直连** — 自动识别国内流量，绕过代理
- 📊 **流量统计** — 实时显示上传/下载速度和已连接时长
- 🌙 **深色主题** — 默认深色，可切换浅色/跟随系统
- 📱 **平板适配** — 支持手机和平板横竖屏

---

## 项目结构

```
susu_vpn/
├── lib/
│   ├── main.dart                    # 入口
│   ├── models/
│   │   └── server_node.dart         # 节点数据模型
│   ├── core/
│   │   ├── theme/app_theme.dart     # 主题配置
│   │   ├── providers/
│   │   │   ├── vpn_provider.dart    # VPN连接状态管理
│   │   │   ├── server_provider.dart # 服务器列表管理
│   │   │   └── settings_provider.dart
│   │   └── services/
│   │       ├── subscription_parser.dart   # 订阅链接解析
│   │       ├── subscription_service.dart  # 订阅拉取/测速
│   │       └── v2ray_config_builder.dart  # v2ray配置生成
│   └── features/
│       ├── home/                    # 主界面
│       ├── servers/                 # 服务器列表
│       └── settings/                # 设置页面
└── android/
    └── app/src/main/kotlin/com/susu/vpn/
        ├── MainActivity.kt          # Flutter主Activity
        └── vpn/
            ├── VpnManager.kt        # VPN权限+生命周期管理
            └── SusuVpnService.kt    # Android VpnService实现
```

---

## 构建步骤

### 1. 环境准备

```bash
# 安装 Flutter 3.x
flutter doctor

# 安装依赖
flutter pub get
```

### 2. 集成 v2ray-core

**Windows (PowerShell):**
```powershell
cd susu_vpn
.\scripts\download_v2ray.ps1
```

**macOS/Linux:**
```bash
cd susu_vpn
chmod +x scripts/download_v2ray.sh
./scripts/download_v2ray.sh
```

这会下载 v2ray 二进制到 `android/app/src/main/jniLibs/` 目录，并下载 `geoip.dat` / `geosite.dat`。

### 3. 构建 APK

```bash
# Debug版（用于测试）
flutter build apk --debug

# Release版
flutter build apk --release

# 分架构打包（体积更小）
flutter build apk --split-per-abi --release
```

输出位置：`build/app/outputs/flutter-apk/`

---

## 技术架构

```
Flutter UI
    │
    │ MethodChannel (com.susu.vpn/vpn_service)
    │
Android VpnManager
    │
    ├── Android VpnService (TUN接口)
    │       └── 建立虚拟网卡, 拦截系统流量
    │
    └── v2ray-core (独立进程)
            ├── 监听 SOCKS5 :10808
            ├── 监听 HTTP   :10809
            └── 根据路由规则转发流量
```

### 流量路径

```
Android App流量
    → TUN虚拟网卡 (10.0.0.2/24)
    → tun2socks (v2ray内置)
    → v2ray路由 (geoip/geosite规则)
    → [国内] → 直连
    → [境外] → VMess/VLESS/Trojan 出站
    → 远程服务器
```

---

## 协议支持

| 协议 | 传输层 | TLS | Reality |
|------|--------|-----|---------|
| VMess | TCP/WS/gRPC/H2/KCP/QUIC | ✅ | ❌ |
| VLESS | TCP/WS/gRPC/H2 | ✅ | ✅ |
| Trojan | TCP/WS/gRPC | ✅ | ❌ |
| Shadowsocks | TCP | ❌ | ❌ |
| SOCKS5 | TCP | ❌ | ❌ |

---

## 订阅格式

内置订阅地址返回的内容为 **Base64 编码**的节点列表，每行一个节点链接：

```
vmess://eyJhZGQiOiAi...
vless://uuid@host:port?...#name
trojan://password@host:port#name
ss://BASE64@host:port#name
```

---

## 注意事项

1. **v2ray二进制版权**：v2ray-core 采用 MIT 协议，可自由使用，但需遵守当地法律。
2. **GeoIP数据**：geoip.dat / geosite.dat 来自 v2fly 社区，每月更新。
3. **VPN权限**：首次启动需用户在系统对话框中授权 VPN 连接。
4. **后台运行**：已配置前台 Service + 通知，确保后台不被杀掉。
5. **签名配置**：发布 Release 版需配置正式签名，参考 Flutter 官方文档。

---

## 开源依赖

- [Flutter](https://flutter.dev) — 跨平台UI框架
- [v2ray-core](https://github.com/v2fly/v2ray-core) — 代理核心
- [provider](https://pub.dev/packages/provider) — 状态管理
- [hive](https://pub.dev/packages/hive) — 本地数据库
- [http](https://pub.dev/packages/http) — HTTP客户端

# 速连VPN2 - 技术架构文档

## 🏗️ 系统架构概览

```
┌─────────────────────────────────────────────────┐
│                 Flutter UI Layer                 │
│  (Home / Servers / Settings Screens)            │
└────────────────┬────────────────────────────────┘
                 │ Provider State Management
┌────────────────▼────────────────────────────────┐
│              Business Logic Layer                │
│  (VpnProvider / ServerProvider / SettingsProv.) │
└────────────────┬────────────────────────────────┘
                 │ Method Channel
┌────────────────▼────────────────────────────────┐
│           Android Native Layer                   │
│  (VpnManager / SusuVpnService)                  │
└────────────────┬────────────────────────────────┘
                 │ Process Communication
┌────────────────▼────────────────────────────────┐
│            v2ray-core Engine                     │
│  (TUN Interface + SOCKS5 Proxy)                 │
└─────────────────────────────────────────────────┘
```

---

## 📦 核心模块说明

### 1. UI层 (lib/features/)

#### Home模块
- **home_screen.dart**: 主界面，包含三个Tab（首页/服务器/设置）
- **widgets/**:
  - `connect_button.dart`: 圆形连接按钮，带动画效果
  - `status_card.dart`: 显示连接状态和时长
  - `traffic_card.dart`: 实时流量统计
  - `server_selector_card.dart`: 当前选中节点信息

#### Servers模块
- **server_list_screen.dart**: 节点列表页面
  - 支持延迟显示（颜色区分）
  - 单个/批量测速功能
  - 节点选择和切换

#### Settings模块
- **settings_screen.dart**: 设置页面
  - 订阅地址配置
  - 连接选项（绕过大陆、UDP、自动重连）
  - 主题切换
  - 高级配置（端口、DNS）

### 2. 业务逻辑层 (lib/core/providers/)

#### VpnProvider
**职责**: VPN连接状态管理

**核心方法**:
```dart
Future<void> connect(ServerNode node)  // 连接VPN
Future<void> disconnect()               // 断开VPN
void _handleStatusChange(String)        // 处理状态变化
Future<void> _fetchStats()              // 获取流量统计
```

**状态机**:
```
DISCONNECTED → CONNECTING → CONNECTED → DISCONNECTING → DISCONNECTED
                    ↓
                  ERROR
```

**通信机制**:
- MethodChannel: `com.susu.vpn/vpn_service`
  - `startVpn`: 启动VPN
  - `stopVpn`: 停止VPN
  - `getStats`: 获取流量统计
- 回调方法:
  - `onStatusChanged`: 状态变化通知
  - `onError`: 错误通知

#### ServerProvider
**职责**: 节点列表管理和测速

**核心方法**:
```dart
Future<void> refreshSubscription()      // 刷新订阅
Future<void> testNodeLatency(String)    // 测试单个节点
Future<void> testAllLatency()           // 批量测速
void selectServer(String)               // 选择节点
void selectFastest()                    // 选择最快节点
```

**数据存储**:
- Hive Box: `servers` - 存储节点列表
- Hive Box: `settings` - 存储选中节点ID

**测速策略**:
- 并发数：8个节点同时测试
- 超时时间：5秒
- 排序规则：按延迟从低到高，超时放最后

#### SettingsProvider
**职责**: 应用配置管理

**配置项**:
```dart
bool bypassCN          // 绕过大陆地址
bool enableUDP         // UDP转发
bool autoReconnect     // 自动重连
ThemeMode themeMode    // 主题模式
int localSocksPort     // Socks5端口
int localHttpPort      // HTTP端口
String dnsServer       // DNS服务器
String subscriptionUrl // 订阅地址（新增）
```

**持久化**: Hive Box `settings`

### 3. 服务层 (lib/core/services/)

#### SubscriptionService
**职责**: 订阅拉取和节点解析

**核心流程**:
```
1. 从Hive读取订阅地址
2. HTTP GET请求订阅链接
3. 接收Base64编码内容
4. 解码并逐行解析
5. 返回ServerNode列表
```

**支持的协议**:
- vmess://
- vless://
- trojan://
- ss:// (Shadowsocks)
- socks5://

**测速实现**:
```dart
// TCP连接测试
final socket = await Socket.connect(host, port, timeout: 5s);
socket.destroy();
return elapsedMilliseconds;
```

#### SubscriptionParser
**职责**: 解析各种协议的节点链接

**解析策略**:
1. **VMess**: Base64解码JSON配置
2. **VLESS/Trojan**: URI解析（userInfo + query params）
3. **Shadowsocks**: Base64解码 userinfo@host:port
4. **SOCKS5**: 标准URI解析

**关键字段映射**:
```
VMess:
  ps → name, add → host, port → port
  id → uuid, aid → alterId, scy → security
  net → network, tls → tls, sni → sni

VLESS:
  userInfo → uuid
  query: type, security, flow, pbk, sid, spx

Trojan:
  userInfo → password
  query: type, sni, path, host
```

#### V2rayConfigBuilder
**职责**: 生成v2ray-core的JSON配置

**配置结构**:
```json
{
  "log": { "loglevel": "warning" },
  "dns": { "servers": ["8.8.8.8", "1.1.1.1"] },
  "inbounds": [
    { "protocol": "socks", "port": 10808 },
    { "protocol": "http", "port": 10809 }
  ],
  "outbounds": [
    { "tag": "proxy", "protocol": "vmess/vless/trojan/..." },
    { "tag": "direct", "protocol": "freedom" },
    { "tag": "block", "protocol": "blackhole" }
  ],
  "routing": {
    "rules": [
      { "domain": "geosite:category-ads-all", "outboundTag": "block" },
      { "ip": "geoip:cn", "outboundTag": "direct" },
      { "network": "tcp,udp", "outboundTag": "proxy" }
    ]
  }
}
```

**传输层配置**:
- TCP: 默认
- WebSocket: wsSettings (path, headers)
- gRPC: grpcSettings (serviceName)
- HTTP/2: httpSettings (path, host)
- KCP: kcpSettings (mtu, tti, seed)
- QUIC: quicSettings (security, key)

**安全配置**:
- TLS: tlsSettings (serverName, fingerprint)
- Reality: realitySettings (publicKey, shortId, spiderX)

### 4. 数据模型 (lib/models/)

#### ServerNode
**字段说明**:
```dart
String id              // 唯一标识（URL hash）
String name            // 节点名称
String host            // 服务器地址
int port               // 端口
ServerProtocol protocol // 协议类型
String uuid            // UUID或密码
String alterId         // VMess alterId
String security        // 加密方式
String network         // 传输协议
String path            // WS路径/gRPC服务名
String host2           // WS Host头
bool tls               // 是否启用TLS
String sni             // TLS SNI
String? fingerprint    // TLS指纹
int? latency           // 延迟(ms)
bool selected          // 是否选中
String rawConfig       // 原始配置字符串
String? flow           // VLESS flow
String? publicKey      // Reality公钥
String? shortId        // Reality短ID
String? spiderX        // Reality spiderX
```

**辅助方法**:
```dart
String get protocolName  // 协议名称（中文）
String get latencyText   // 延迟文本（-- / XXms / 超时）
Color get latencyColor   // 延迟颜色（绿/黄/红）
Map<String, dynamic> toJson()  // 序列化
factory fromJson()      // 反序列化
```

### 5. Android原生层 (android/app/src/main/kotlin/)

#### MainActivity
**职责**: Flutter与Native通信桥梁

**MethodChannel注册**:
```kotlin
MethodChannel(flutterEngine, "com.susu.vpn/vpn_service")
  .setMethodCallHandler { call, result ->
    when (call.method) {
      "startVpn" -> vpnManager.startVpn(config, nodeName, result)
      "stopVpn" -> vpnManager.stopVpn(result)
      "getStats" -> result.success(vpnManager.getStats())
    }
  }
```

**生命周期管理**:
```kotlin
override fun onActivityResult() -> vpnManager.onActivityResult()
override fun onDestroy() -> vpnManager.release()
```

#### VpnManager
**职责**: VPN服务协调器

**核心流程**:
```
1. 检查VPN权限 (VpnService.prepare)
2. 如需授权，启动系统对话框
3. 用户授权后，启动SusuVpnService
4. 绑定Service，建立双向通信
5. 监听状态变化，通知Flutter
```

**ServiceConnection**:
```kotlin
vpnService?.setStatusCallback { status ->
  flutterChannel?.invokeMethod("onStatusChanged", status)
}
```

#### SusuVpnService
**职责**: Android VpnService实现

**架构**:
```
TUN Interface (10.0.0.2/24)
    ↓
IP Packet Reader Thread
    ↓
v2ray-core Process (SOCKS5 :10808)
    ↓
Remote Server
```

**关键步骤**:
1. **写入配置文件**: `filesDir/v2ray/config.json`
2. **启动v2ray进程**: `ProcessBuilder(libv2ray.so, "run", "-c", config)`
3. **等待端口就绪**: 轮询127.0.0.1:10808（最多5秒）
4. **建立TUN接口**: 
   ```kotlin
   Builder()
     .addAddress("10.0.0.2", 24)
     .addRoute("0.0.0.0", 0)
     .addDnsServer("8.8.8.8")
     .establish()
   ```
5. **启动流量监控**: 两个后台线程分别统计上下行
6. **前台服务**: 显示通知，防止被系统杀掉

**流量统计**:
```kotlin
// 上行：直接从TUN设备读取
uploadBytes.addAndGet(length.toLong())

// 下行：基于上行估算（系数1.2）
downloadBytes.addAndGet((uploadDiff * 1.2).toLong())
```

---

## 🔄 数据流图

### 连接流程
```
User Click Connect Button
    ↓
VpnProvider.connect(node)
    ↓
V2rayConfigBuilder.toJsonString(node)
    ↓
MethodChannel.invokeMethod("startVpn", {config})
    ↓
MainActivity.receive()
    ↓
VpnManager.startVpn()
    ↓
VpnService.prepare() → Permission Dialog (if needed)
    ↓
Start SusuVpnService
    ↓
Write config.json
    ↓
Start v2ray-core Process
    ↓
Wait for Port 10808
    ↓
Establish TUN Interface
    ↓
Start Traffic Monitoring Threads
    ↓
Notify Status: CONNECTED
    ↓
Flutter receives callback
    ↓
UI updates to connected state
```

### 订阅刷新流程
```
User Click Refresh Button
    ↓
ServerProvider.refreshSubscription()
    ↓
SubscriptionService.fetchNodes()
    ↓
HTTP GET subscription_url
    ↓
Receive Base64 encoded content
    ↓
Decode and split lines
    ↓
SubscriptionParser.parse(line)
    ↓
Create ServerNode objects
    ↓
Save to Hive Box 'servers'
    ↓
Update UI with new nodes
```

---

## 🗄️ 数据存储

### Hive数据库

**Box: servers**
```dart
TypeAdapter: ServerNodeAdapter (typeId: 0)
TypeAdapter: ServerProtocolAdapter (typeId: 1)
Storage: List<ServerNode>
```

**Box: settings**
```dart
Key-Value pairs:
- selectedServerId: String
- subscriptionUrl: String
- bypassCN: bool
- enableUDP: bool
- autoReconnect: bool
- themeMode: String ('dark'/'light'/'system')
- localSocksPort: int
- localHttpPort: int
- dnsServer: String
```

---

## 🔌 依赖关系

### Flutter Dependencies
```yaml
provider: ^6.1.2          # 状态管理
http: ^1.2.0              # HTTP客户端
shared_preferences: ^2.2.3 # 简单KV存储
hive: ^2.2.3              # 本地数据库
hive_flutter: ^1.1.0      # Hive Flutter集成
logger: ^2.3.0            # 日志系统
```

### Android Dependencies
```gradle
kotlin-stdlib-jdk7
androidx.core:core-ktx
androidx.appcompat:appcompat
com.google.android.material:material
androidx.multidex:multidex
androidx.lifecycle:lifecycle-runtime-ktx
androidx.lifecycle:lifecycle-service
```

---

## 🛡️ 安全考虑

### 敏感信息保护
1. **订阅地址**: 存储在本地Hive数据库，不硬编码
2. **节点配置**: 仅保存在内存和本地存储
3. **Git忽略**: `.gitignore` 包含数据库文件

### 权限最小化
```xml
INTERNET                    # 网络访问
ACCESS_NETWORK_STATE        # 网络状态
CHANGE_NETWORK_STATE        # 网络切换
FOREGROUND_SERVICE          # 前台服务
BIND_VPN_SERVICE            # VPN绑定
```

### 代码混淆
```proguard
# proguard-rules.pro
-keep class com.susu.vpn.** { *; }
-keep class io.flutter.** { *; }
```

---

## 🚀 性能优化

### UI优化
- 使用 `IndexedStack` 保持Tab状态
- `Consumer` 精确更新，避免全局重建
- 图片资源压缩和缓存

### 网络优化
- HTTP请求超时控制（15秒）
- 并发测速限制（8个）
- 连接池复用

### 内存优化
- 及时取消Timer和Stream订阅
- Daemon线程避免阻塞
- 大对象及时释放

---

## 🧪 测试建议

### 单元测试
```dart
// 测试订阅解析
test('parse vmess link', () {
  final nodes = SubscriptionParser.parse(vmessLink);
  expect(nodes.length, 1);
  expect(nodes[0].protocol, ServerProtocol.vmess);
});

// 测试配置生成
test('build v2ray config', () {
  final config = V2rayConfigBuilder.build(node);
  expect(config['outbounds'][0]['protocol'], 'vmess');
});
```

### 集成测试
```dart
// 测试完整连接流程
testWidgets('connect and disconnect', (tester) async {
  await tester.tap(connectButton);
  await tester.pumpAndSettle();
  expect(find.text('已连接'), findsOneWidget);
});
```

---

## 📈 监控和日志

### 日志级别
- **DEBUG**: 详细调试信息
- **INFO**: 正常操作流程
- **WARNING**: 潜在问题
- **ERROR**: 错误和异常

### 关键日志点
1. VPN连接/断开
2. 订阅拉取开始/结束
3. 节点解析结果
4. 所有异常捕获

### 日志格式
```
[TIME] [LEVEL] [CATEGORY] Message
例: [14:30:25] [INFO] [🔌 VPN] 尝试连接节点: 日本东京 (1.2.3.4:443)
```

---

## 🔮 未来扩展

### 插件架构
```dart
abstract class VpnPlugin {
  String get name;
  Future<void> initialize();
  Future<Map<String, dynamic>> getConfig();
}
```

### API接口
```kotlin
// v2ray stats API
GET http://127.0.0.1:10810/debug/vars
Response: {
  "uplink": 123456,
  "downlink": 789012
}
```

### 云端同步
```dart
class CloudSync {
  Future<void> uploadConfig();
  Future<void> downloadConfig();
  Future<List<String>> getSubscriptions();
}
```

---

**文档版本**: 1.0  
**更新日期**: 2026-05-15  
**维护者**: 速连VPN开发团队

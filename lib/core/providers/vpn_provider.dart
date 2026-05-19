import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/server_node.dart';
import '../services/v2ray_config_builder.dart';
import '../utils/app_logger.dart';

enum VpnStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

class VpnProvider extends ChangeNotifier {
  VpnStatus _status = VpnStatus.disconnected;
  String _errorMessage = '';
  DateTime? _connectedAt;
  int _uploadBytes = 0;
  int _downloadBytes = 0;
  Timer? _statsTimer;
  ServerNode? _currentNode;

  // Android VPN Service通信通道
  static const MethodChannel _vpnChannel =
      MethodChannel('com.susu.vpn/vpn_service');
  static const EventChannel _statsChannel =
      EventChannel('com.susu.vpn/vpn_stats');

  VpnStatus get status => _status;
  String get errorMessage => _errorMessage;
  DateTime? get connectedAt => _connectedAt;
  int get uploadBytes => _uploadBytes;
  int get downloadBytes => _downloadBytes;
  ServerNode? get currentNode => _currentNode;

  bool get isConnected => _status == VpnStatus.connected;
  bool get isConnecting => _status == VpnStatus.connecting;
  bool get isDisconnected =>
      _status == VpnStatus.disconnected || _status == VpnStatus.error;

  String get statusText {
    switch (_status) {
      case VpnStatus.disconnected:
        return '未连接';
      case VpnStatus.connecting:
        return '连接中...';
      case VpnStatus.connected:
        return '已连接';
      case VpnStatus.disconnecting:
        return '断开中...';
      case VpnStatus.error:
        return '连接失败';
    }
  }

  String get connectedDuration {
    if (_connectedAt == null) return '00:00:00';
    final duration = DateTime.now().difference(_connectedAt!);
    final h = duration.inHours.toString().padLeft(2, '0');
    final m = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final s = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get uploadSpeed => _formatBytes(_uploadBytes);
  String get downloadSpeed => _formatBytes(_downloadBytes);

  VpnProvider() {
    _setupVpnListener();
  }

  void _setupVpnListener() {
    _vpnChannel.setMethodCallHandler((call) async {
      AppLogger.d('收到原生层调用: ${call.method}');
      switch (call.method) {
        case 'onStatusChanged':
          _handleStatusChange(call.arguments as String);
          break;
        case 'onError':
          _handleError(call.arguments as String);
          break;
        default:
          AppLogger.w('未知的方法调用: ${call.method}');
      }
    });
  }

  void _handleStatusChange(String statusStr) {
    switch (statusStr) {
      case 'CONNECTING':
        _status = VpnStatus.connecting;
        break;
      case 'CONNECTED':
        _status = VpnStatus.connected;
        _connectedAt = DateTime.now();
        _startStatsTimer();
        break;
      case 'DISCONNECTING':
        _status = VpnStatus.disconnecting;
        break;
      case 'DISCONNECTED':
        _status = VpnStatus.disconnected;
        _connectedAt = null;
        _uploadBytes = 0;
        _downloadBytes = 0;
        _stopStatsTimer();
        _currentNode = null;
        break;
    }
    notifyListeners();
  }

  void _handleError(String message) {
    _status = VpnStatus.error;
    _errorMessage = message;
    _currentNode = null;
    _stopStatsTimer();
    notifyListeners();
  }

  Future<void> connect(ServerNode node) async {
    AppLogger.vpn('尝试连接节点: ${node.name} (${node.host}:${node.port})');
    
    if (_status == VpnStatus.connecting || _status == VpnStatus.connected) {
      AppLogger.vpn('先断开现有连接');
      await disconnect();
      // 等待断开完成
      await Future.delayed(const Duration(milliseconds: 500));
    }

    _status = VpnStatus.connecting;
    _errorMessage = '';
    _currentNode = node;
    notifyListeners();

    try {
      // 生成V2Ray配置
      AppLogger.d('生成V2Ray配置');
      final config = V2rayConfigBuilder.toJsonString(node);
      AppLogger.d('配置长度: ${config.length} 字符');

      // 调用Android原生VPN Service，添加超时处理
      AppLogger.vpn('启动VPN服务...');
      final result = await _vpnChannel.invokeMethod('startVpn', {
        'config': config,
        'nodeName': node.name,
        'host': node.host,
        'port': node.port,
      }).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('连接超时（30秒），请检查：\n1. 网络连接是否正常\n2. 节点是否可用\n3. v2ray核心是否正确安装');
        },
      );

      if (result == false) {
        AppLogger.e('启动VPN服务失败');
        _status = VpnStatus.error;
        _errorMessage = '启动VPN服务失败，请检查v2ray核心是否正确安装';
        _currentNode = null;
        notifyListeners();
      } else {
        AppLogger.vpn('VPN服务启动成功，等待连接...');
      }
    } on PlatformException catch (e) {
      AppLogger.e('PlatformException: ${e.message}', e);
      _status = VpnStatus.error;
      _errorMessage = e.message ?? '连接失败';
      if (e.details != null) {
        _errorMessage += '\n详情: ${e.details}';
      }
      _currentNode = null;
      notifyListeners();
    } on TimeoutException catch (_) {
      AppLogger.e('连接超时');
      _status = VpnStatus.error;
      _errorMessage = '连接超时，请检查网络或节点状态';
      _currentNode = null;
      notifyListeners();
    } catch (e) {
      AppLogger.e('连接异常: $e', e);
      _status = VpnStatus.error;
      _errorMessage = '连接失败: ${e.toString()}';
      _currentNode = null;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    _status = VpnStatus.disconnecting;
    notifyListeners();

    try {
      await _vpnChannel.invokeMethod('stopVpn');
    } catch (_) {}
  }

  void _startStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _fetchStats();
      notifyListeners(); // 更新时长显示
    });
  }

  void _stopStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = null;
  }

  Future<void> _fetchStats() async {
    try {
      final result = await _vpnChannel.invokeMethod('getStats');
      if (result != null) {
        _uploadBytes = result['upload'] ?? 0;
        _downloadBytes = result['download'] ?? 0;
        notifyListeners();
      }
    } catch (_) {}
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(2)}MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)}GB';
  }

  @override
  void dispose() {
    _stopStatsTimer();
    super.dispose();
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../services/subscription_parser.dart';
import '../../models/server_node.dart';
import '../utils/app_logger.dart';

class SubscriptionService {
  // 默认订阅地址（可通过设置修改）
  static const String _defaultSubscriptionUrl = '';

  static const Duration _timeout = Duration(seconds: 15);

  /// 获取订阅地址（从本地存储读取）
  static String _getSubscriptionUrl() {
    try {
      final box = Hive.box('settings');
      final url = box.get('subscriptionUrl', defaultValue: _defaultSubscriptionUrl);
      return url.toString().trim();
    } catch (_) {
      return _defaultSubscriptionUrl;
    }
  }

  /// 设置订阅地址
  static Future<void> setSubscriptionUrl(String url) async {
    try {
      final box = Hive.box('settings');
      await box.put('subscriptionUrl', url.trim());
    } catch (_) {}
  }

  /// 从订阅地址拉取并解析节点列表
  static Future<List<ServerNode>> fetchNodes() async {
    final subscriptionUrl = _getSubscriptionUrl();
    
    if (subscriptionUrl.isEmpty) {
      AppLogger.e('订阅地址未配置');
      throw Exception('请先在设置中配置订阅地址');
    }

    AppLogger.subscription('开始获取订阅: $subscriptionUrl');

    try {
      final response = await http
          .get(
            Uri.parse(subscriptionUrl),
            headers: {
              'User-Agent': 'v2rayN/6.0',
              'Accept': '*/*',
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        String body = response.body;
        AppLogger.subscription('订阅请求成功，开始解析');
        List<ServerNode> nodes = SubscriptionParser.parse(body);
        AppLogger.subscription('解析完成，共 ${nodes.length} 个节点');
        return nodes;
      } else {
        AppLogger.e('订阅请求失败: HTTP ${response.statusCode}');
        throw Exception('订阅请求失败: HTTP ${response.statusCode}');
      }
    } on SocketException {
      AppLogger.e('网络连接失败');
      throw Exception('网络连接失败，请检查网络设置');
    } on HttpException {
      AppLogger.e('HTTP请求异常');
      throw Exception('HTTP请求异常');
    } catch (e) {
      AppLogger.e('获取订阅失败: $e');
      throw Exception('获取订阅失败: $e');
    }
  }

  /// 测试节点延迟
  static Future<int> testLatency(ServerNode node) async {
    final stopwatch = Stopwatch()..start();
    try {
      final socket = await Socket.connect(
        node.host,
        node.port,
        timeout: const Duration(seconds: 5),
      );
      socket.destroy();
      stopwatch.stop();
      return stopwatch.elapsedMilliseconds;
    } catch (_) {
      stopwatch.stop();
      return -1; // 超时或连接失败
    }
  }

  /// 批量测速（限制并发数）
  static Future<Map<String, int>> batchTestLatency(
    List<ServerNode> nodes, {
    int concurrency = 5,
    void Function(String id, int latency)? onResult,
  }) async {
    Map<String, int> results = {};
    int index = 0;

    Future<void> worker() async {
      while (index < nodes.length) {
        final node = nodes[index++];
        final latency = await testLatency(node);
        results[node.id] = latency;
        onResult?.call(node.id, latency);
      }
    }

    List<Future<void>> workers = List.generate(
      concurrency.clamp(1, nodes.length),
      (_) => worker(),
    );

    await Future.wait(workers);
    return results;
  }
}

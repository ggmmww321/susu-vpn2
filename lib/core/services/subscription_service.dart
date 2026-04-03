import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../services/subscription_parser.dart';
import '../../models/server_node.dart';

class SubscriptionService {
  // 订阅地址（内置，不对外暴露）
  static const String _subscriptionUrl =
      'https://mark-35w.pages.dev/sub?token=999edc1ac844fff7906123405321e24c';

  static const Duration _timeout = Duration(seconds: 15);

  /// 从订阅地址拉取并解析节点列表
  static Future<List<ServerNode>> fetchNodes() async {
    try {
      final response = await http
          .get(
            Uri.parse(_subscriptionUrl),
            headers: {
              'User-Agent': 'v2rayN/6.0',
              'Accept': '*/*',
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        String body = response.body;
        List<ServerNode> nodes = SubscriptionParser.parse(body);
        return nodes;
      } else {
        throw Exception('订阅请求失败: HTTP ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('网络连接失败，请检查网络设置');
    } on HttpException {
      throw Exception('HTTP请求异常');
    } catch (e) {
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

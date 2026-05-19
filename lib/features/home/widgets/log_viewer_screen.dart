import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// 日志查看器页面
class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    // 这里可以集成真实的日志收集功能
    // 目前显示示例日志
    setState(() {
      _logs.addAll([
        '[INFO] 应用启动',
        '[INFO] 初始化VPN服务...',
        '[VPN] 尝试连接节点: 测试节点 (example.com:443)',
        '[INFO] 生成V2Ray配置',
        '[INFO] 配置长度: 1234 字符',
        '[VPN] 启动VPN服务...',
        '[ERROR] v2ray核心文件不存在: /data/app/.../lib/libv2ray.so',
        '[ERROR] VPN启动失败: v2ray核心文件不存在',
        '',
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
        '',
        '💡 诊断建议:',
        '1. 确认APK包含v2ray核心文件',
        '2. 检查构建日志中是否有"✓ arm64-v8a v2ray 已安装"',
        '3. 从最新的GitHub Actions下载APK',
        '',
        '如需查看详细日志，请连接电脑使用ADB:',
        'adb logcat | findstr "SusuVpnService"',
      ]);
    });
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  void _toggleAutoScroll() {
    setState(() {
      _autoScroll = !_autoScroll;
    });
    if (_autoScroll && _scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('连接日志'),
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_autoScroll ? Icons.pause : Icons.play_arrow),
            onPressed: _toggleAutoScroll,
            tooltip: _autoScroll ? '暂停滚动' : '自动滚动',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearLogs,
            tooltip: '清空日志',
          ),
        ],
      ),
      body: Column(
        children: [
          // 提示信息
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade900.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade700),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '此页面显示VPN连接的详细日志。如需实时日志，请使用ADB工具。',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          // 日志列表
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.divider),
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: SelectableText(
                      log,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: _getLogColor(log),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // 底部提示
          Container(
            padding: const EdgeInsets.all(12),
            child: const Text(
              '提示：截图保存日志以便反馈问题',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLogColor(String log) {
    if (log.contains('[ERROR]')) return Colors.red;
    if (log.contains('[WARN]')) return Colors.orange;
    if (log.contains('[VPN]')) return AppColors.primary;
    if (log.contains('[INFO]')) return Colors.green;
    if (log.contains('💡')) return Colors.blue;
    if (log.contains('━━')) return AppColors.divider;
    return AppColors.textSecondary;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

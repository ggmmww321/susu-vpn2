import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/server_node.dart';
import '../services/subscription_service.dart';

enum UpdateStatus { idle, loading, success, error }

class ServerProvider extends ChangeNotifier {
  List<ServerNode> _nodes = [];
  String? _selectedId;
  UpdateStatus _updateStatus = UpdateStatus.idle;
  String _statusMessage = '';
  bool _isTesting = false;
  Set<String> _testingIds = {};

  List<ServerNode> get nodes => _nodes;
  String? get selectedId => _selectedId;
  ServerNode? get selectedNode =>
      _nodes.isEmpty ? null : _nodes.where((n) => n.id == _selectedId).firstOrNull;
  UpdateStatus get updateStatus => _updateStatus;
  String get statusMessage => _statusMessage;
  bool get isTesting => _isTesting;
  Set<String> get testingIds => _testingIds;

  ServerProvider() {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final box = Hive.box<ServerNode>('servers');
    _nodes = box.values.toList();

    final settingsBox = Hive.box('settings');
    _selectedId = settingsBox.get('selectedServerId');

    // 如果没有选中节点但有节点列表，选第一个
    if (_selectedId == null && _nodes.isNotEmpty) {
      _selectedId = _nodes.first.id;
    }

    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    final box = Hive.box<ServerNode>('servers');
    await box.clear();
    for (final node in _nodes) {
      await box.put(node.id, node);
    }
  }

  Future<void> saveSelectedId() async {
    final settingsBox = Hive.box('settings');
    await settingsBox.put('selectedServerId', _selectedId);
  }

  /// 选择服务器
  void selectServer(String id) {
    _selectedId = id;
    saveSelectedId();
    notifyListeners();
  }

  /// 刷新订阅（拉取节点）
  Future<void> refreshSubscription() async {
    _updateStatus = UpdateStatus.loading;
    _statusMessage = '正在获取服务器列表...';
    notifyListeners();

    try {
      final newNodes = await SubscriptionService.fetchNodes();

      if (newNodes.isEmpty) {
        _updateStatus = UpdateStatus.error;
        _statusMessage = '未获取到可用服务器';
        notifyListeners();
        return;
      }

      // 保留原来的延迟数据
      final Map<String, int?> oldLatencies = {
        for (var n in _nodes) n.id: n.latency
      };

      _nodes = newNodes.map((n) {
        if (oldLatencies.containsKey(n.id)) {
          n.latency = oldLatencies[n.id];
        }
        return n;
      }).toList();

      // 检查选中节点是否还在列表中
      if (_selectedId != null && !_nodes.any((n) => n.id == _selectedId)) {
        _selectedId = _nodes.isNotEmpty ? _nodes.first.id : null;
      }
      if (_selectedId == null && _nodes.isNotEmpty) {
        _selectedId = _nodes.first.id;
      }

      await _saveToStorage();
      await saveSelectedId();

      _updateStatus = UpdateStatus.success;
      _statusMessage = '已更新 ${_nodes.length} 个服务器';
      notifyListeners();
    } catch (e) {
      _updateStatus = UpdateStatus.error;
      _statusMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  /// 测试单个节点延迟
  Future<void> testNodeLatency(String id) async {
    final index = _nodes.indexWhere((n) => n.id == id);
    if (index < 0) return;

    _testingIds.add(id);
    notifyListeners();

    final latency = await SubscriptionService.testLatency(_nodes[index]);
    _nodes[index].latency = latency;
    _testingIds.remove(id);
    await _saveToStorage();
    notifyListeners();
  }

  /// 批量测速所有节点
  Future<void> testAllLatency() async {
    if (_isTesting) return;
    _isTesting = true;
    _testingIds = _nodes.map((n) => n.id).toSet();
    notifyListeners();

    await SubscriptionService.batchTestLatency(
      _nodes,
      concurrency: 8,
      onResult: (id, latency) {
        final index = _nodes.indexWhere((n) => n.id == id);
        if (index >= 0) {
          _nodes[index].latency = latency;
          _testingIds.remove(id);
          notifyListeners();
        }
      },
    );

    // 按延迟排序（超时放最后）
    _nodes.sort((a, b) {
      int la = a.latency ?? 9999;
      int lb = b.latency ?? 9999;
      if (la < 0) la = 9999;
      if (lb < 0) lb = 9999;
      return la.compareTo(lb);
    });

    _isTesting = false;
    _testingIds.clear();
    await _saveToStorage();
    notifyListeners();
  }

  /// 选择延迟最低的节点
  void selectFastest() {
    final available = _nodes.where((n) => n.latency != null && n.latency! > 0).toList();
    if (available.isEmpty) return;
    available.sort((a, b) => a.latency!.compareTo(b.latency!));
    selectServer(available.first.id);
  }

  void resetStatus() {
    _updateStatus = UpdateStatus.idle;
    _statusMessage = '';
    notifyListeners();
  }
}

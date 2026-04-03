import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/server_provider.dart';
import '../../core/providers/vpn_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/server_node.dart';

class ServerListScreen extends StatefulWidget {
  final bool isModal;
  const ServerListScreen({super.key, this.isModal = false});

  @override
  State<ServerListScreen> createState() => _ServerListScreenState();
}

class _ServerListScreenState extends State<ServerListScreen> {
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('选择服务器'),
        leading: widget.isModal
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          Consumer<ServerProvider>(
            builder: (context, server, _) {
              return IconButton(
                tooltip: '全部测速',
                icon: server.isTesting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(Icons.speed_rounded),
                onPressed:
                    server.isTesting ? null : () => server.testAllLatency(),
              );
            },
          ),
          Consumer<ServerProvider>(
            builder: (context, server, _) {
              return IconButton(
                tooltip: '刷新订阅',
                icon: server.updateStatus == UpdateStatus.loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded),
                onPressed: server.updateStatus == UpdateStatus.loading
                    ? null
                    : () => server.refreshSubscription(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchText = v),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: '搜索服务器...',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
                  suffixIcon: _searchText.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textHint),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchText = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          Expanded(
            child: Consumer2<ServerProvider, VpnProvider>(
              builder: (context, server, vpn, _) {
                if (server.updateStatus == UpdateStatus.loading &&
                    server.nodes.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text('正在获取服务器列表...',
                            style:
                                TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }

                if (server.nodes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off_rounded,
                            size: 64, color: AppColors.textHint),
                        const SizedBox(height: 16),
                        const Text('暂无服务器',
                            style:
                                TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => server.refreshSubscription(),
                          icon: const Icon(Icons.refresh_rounded,
                              color: AppColors.primary),
                          label: const Text('点击刷新',
                              style:
                                  TextStyle(color: AppColors.primary)),
                        ),
                      ],
                    ),
                  );
                }

                final filtered = _searchText.isEmpty
                    ? server.nodes
                    : server.nodes
                        .where((n) =>
                            n.name
                                .toLowerCase()
                                .contains(_searchText.toLowerCase()) ||
                            n.host.contains(_searchText))
                        .toList();

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final node = filtered[index];
                    final isSelected = server.selectedId == node.id;
                    final isTesting = server.testingIds.contains(node.id);

                    return _ServerNodeTile(
                      node: node,
                      isSelected: isSelected,
                      isTesting: isTesting,
                      isConnected: vpn.isConnected &&
                          vpn.currentNode?.id == node.id,
                      onTap: () {
                        server.selectServer(node.id);
                        if (widget.isModal) Navigator.pop(context);
                      },
                      onTestSpeed: () => server.testNodeLatency(node.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ServerNodeTile extends StatelessWidget {
  final ServerNode node;
  final bool isSelected;
  final bool isTesting;
  final bool isConnected;
  final VoidCallback onTap;
  final VoidCallback onTestSpeed;

  const _ServerNodeTile({
    required this.node,
    required this.isSelected,
    required this.isTesting,
    required this.isConnected,
    required this.onTap,
    required this.onTestSpeed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onTestSpeed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isConnected ? AppColors.primary.withOpacity(0.1) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : isConnected
                    ? AppColors.connected
                    : AppColors.divider,
            width: isSelected || isConnected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // 协议徽章
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  node.protocolName.substring(0, 1),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 节点信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${node.host}:${node.port}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 延迟/测速按钮
            if (isTesting)
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            else if (node.latency != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: node.latencyColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  node.latencyText,
                  style: TextStyle(
                    color: node.latencyColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: onTestSpeed,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: const Icon(
                    Icons.speed_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            // 选中指示
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                size: 20,
                color: AppColors.primary,
              )
            else if (isConnected)
              const Icon(
                Icons.signal_cellular_connected_no_internet_4_bar_rounded,
                size: 20,
                color: AppColors.connected,
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/server_provider.dart';
import '../../../core/providers/vpn_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/server_node.dart';
import '../../servers/server_list_screen.dart';

class ServerSelectorCard extends StatelessWidget {
  const ServerSelectorCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ServerProvider, VpnProvider>(
      builder: (context, server, vpn, _) {
        final selected = server.selectedNode;

        return GestureDetector(
          onTap: vpn.isConnected
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ServerListScreen(isModal: true),
                    ),
                  );
                },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected != null
                    ? AppColors.primary.withOpacity(0.3)
                    : AppColors.divider,
              ),
            ),
            child: Row(
              children: [
                // 协议图标
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      selected?.protocolName.substring(0, 1) ?? '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
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
                        selected?.name ?? '未选择服务器',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            selected != null
                                ? '${selected.host}:${selected.port}'
                                : '请选择服务器',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (selected?.latency != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: selected!.latencyColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                selected.latencyText,
                                style: TextStyle(
                                  color: selected.latencyColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // 箭头
                if (!vpn.isConnected)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textHint,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

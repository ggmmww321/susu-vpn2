import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/vpn_provider.dart';
import '../../../core/theme/app_theme.dart';

class StatusCard extends StatelessWidget {
  const StatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VpnProvider>(
      builder: (context, vpn, _) {
        return Column(
          children: [
            // 状态文字
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                vpn.statusText,
                key: ValueKey(vpn.status),
                style: TextStyle(
                  color: _getStatusColor(vpn.status),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 6),
            // 连接时长
            if (vpn.isConnected) ...[
              StreamBuilder(
                stream: Stream.periodic(const Duration(seconds: 1)),
                builder: (context, _) {
                  return Text(
                    vpn.connectedDuration,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  );
                },
              ),
            ] else ...[
              Text(
                vpn.isConnecting
                    ? '正在建立安全连接...'
                    : vpn.status == VpnStatus.error
                        ? vpn.errorMessage
                        : '点击按钮开始连接',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        );
      },
    );
  }

  Color _getStatusColor(VpnStatus status) {
    switch (status) {
      case VpnStatus.connected:
        return AppColors.connected;
      case VpnStatus.connecting:
        return AppColors.connecting;
      case VpnStatus.error:
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}

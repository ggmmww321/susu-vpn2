import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/vpn_provider.dart';
import '../../../core/theme/app_theme.dart';

class TrafficCard extends StatelessWidget {
  const TrafficCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VpnProvider>(
      builder: (context, vpn, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: _TrafficItem(
                  icon: Icons.arrow_upward_rounded,
                  iconColor: AppColors.primary,
                  label: '上传',
                  value: vpn.isConnected ? vpn.uploadSpeed : '--',
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: AppColors.divider,
              ),
              Expanded(
                child: _TrafficItem(
                  icon: Icons.arrow_downward_rounded,
                  iconColor: AppColors.connected,
                  label: '下载',
                  value: vpn.isConnected ? vpn.downloadSpeed : '--',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TrafficItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _TrafficItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

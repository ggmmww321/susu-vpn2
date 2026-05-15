import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/services/subscription_service.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('设置')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              const _SectionHeader(title: '订阅设置'),
              _SubscriptionUrlTile(),
              const SizedBox(height: 20),
              const _SectionHeader(title: '连接设置'),
              _SettingsCard(children: [
                _SwitchTile(
                  icon: Icons.flag_outlined,
                  iconColor: const Color(0xFFFF6B6B),
                  title: '绕过大陆地址',
                  subtitle: '国内网站直连，不走代理',
                  value: settings.bypassCN,
                  onChanged: settings.setBypassCN,
                ),
                const _Divider(),
                _SwitchTile(
                  icon: Icons.sync_alt_rounded,
                  iconColor: AppColors.primary,
                  title: '启用UDP转发',
                  subtitle: '部分游戏和应用需要',
                  value: settings.enableUDP,
                  onChanged: settings.setEnableUDP,
                ),
                const _Divider(),
                _SwitchTile(
                  icon: Icons.autorenew_rounded,
                  iconColor: const Color(0xFF4CAF50),
                  title: '断线自动重连',
                  subtitle: '网络中断后自动尝试重连',
                  value: settings.autoReconnect,
                  onChanged: settings.setAutoReconnect,
                ),
              ]),
              const SizedBox(height: 20),
              const _SectionHeader(title: '外观'),
              _SettingsCard(children: [
                _ThemeTile(
                  current: settings.themeMode,
                  onChanged: settings.setThemeMode,
                ),
              ]),
              const SizedBox(height: 20),
              const _SectionHeader(title: '高级'),
              _SettingsCard(children: [
                _InfoTile(
                  icon: Icons.settings_ethernet_rounded,
                  iconColor: const Color(0xFFFFC107),
                  title: 'Socks5 端口',
                  value: '${settings.localSocksPort}',
                ),
                const _Divider(),
                _InfoTile(
                  icon: Icons.http_rounded,
                  iconColor: const Color(0xFF9C27B0),
                  title: 'HTTP 端口',
                  value: '${settings.localHttpPort}',
                ),
                const _Divider(),
                _InfoTile(
                  icon: Icons.dns_rounded,
                  iconColor: const Color(0xFF03A9F4),
                  title: 'DNS 服务器',
                  value: settings.dnsServer,
                ),
              ]),
              const SizedBox(height: 20),
              const _SectionHeader(title: '关于'),
              _SettingsCard(children: [
                _InfoTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: AppColors.textSecondary,
                  title: '版本',
                  value: '1.0.0',
                ),
                const _Divider(),
                _InfoTile(
                  icon: Icons.shield_outlined,
                  iconColor: AppColors.primary,
                  title: '协议支持',
                  value: 'VMess · VLESS · Trojan · SS',
                ),
              ]),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────── 复用小组件 ───────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 56),
      child: Divider(height: 1, color: AppColors.divider),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final Future<void> Function(bool) onChanged;

  const _SwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _IconBadge(icon: icon, color: iconColor),
      title: Text(title,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: (v) => onChanged(v),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _IconBadge(icon: icon, color: iconColor),
      title: Text(title,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
      trailing: Text(value,
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 13)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final ThemeMode current;
  final Future<void> Function(ThemeMode) onChanged;

  const _ThemeTile({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const _IconBadge(
          icon: Icons.brightness_6_rounded, color: Color(0xFFFF9800)),
      title: const Text('主题',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 15)),
      trailing: DropdownButton<ThemeMode>(
        value: current,
        dropdownColor: AppColors.bgCard,
        underline: const SizedBox(),
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        items: const [
          DropdownMenuItem(
              value: ThemeMode.dark,
              child: Text('深色', style: TextStyle(color: AppColors.textPrimary))),
          DropdownMenuItem(
              value: ThemeMode.light,
              child: Text('浅色', style: TextStyle(color: AppColors.textPrimary))),
          DropdownMenuItem(
              value: ThemeMode.system,
              child: Text('跟随系统', style: TextStyle(color: AppColors.textPrimary))),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

class _SubscriptionUrlTile extends StatefulWidget {
  const _SubscriptionUrlTile();

  @override
  State<_SubscriptionUrlTile> createState() => _SubscriptionUrlTileState();
}

class _SubscriptionUrlTileState extends State<_SubscriptionUrlTile> {
  String _currentUrl = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUrl();
  }

  Future<void> _loadCurrentUrl() async {
    try {
      final box = Hive.box('settings');
      setState(() {
        _currentUrl = box.get('subscriptionUrl', defaultValue: '') as String;
      });
    } catch (_) {}
  }

  Future<void> _showEditDialog() async {
    final controller = TextEditingController(text: _currentUrl);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text(
          '配置订阅地址',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: '请输入订阅链接',
            hintStyle: TextStyle(color: AppColors.textSecondary),
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('保存', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      await SubscriptionService.setSubscriptionUrl(result);
      setState(() {
        _currentUrl = result.trim();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('订阅地址已保存'),
            backgroundColor: AppColors.connected,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      children: [
        ListTile(
          leading: const _IconBadge(
            icon: Icons.link_rounded,
            color: AppColors.primary,
          ),
          title: const Text(
            '订阅地址',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
          ),
          subtitle: Text(
            _currentUrl.isEmpty ? '点击配置订阅链接' : _currentUrl.length > 30
                ? '${_currentUrl.substring(0, 30)}...'
                : _currentUrl,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(
            Icons.edit_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          onTap: _showEditDialog,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/vpn_provider.dart';
import '../../core/providers/server_provider.dart';
import '../../core/theme/app_theme.dart';
import '../servers/server_list_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/connect_button.dart';
import 'widgets/status_card.dart';
import 'widgets/traffic_card.dart';
import 'widgets/server_selector_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // 首次启动自动拉取订阅
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final serverProvider = context.read<ServerProvider>();
      if (serverProvider.nodes.isEmpty) {
        serverProvider.refreshSubscription().then((_) {
          // 检查是否有错误
          if (serverProvider.updateStatus == UpdateStatus.error && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(serverProvider.statusMessage),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _HomeTab(),
          ServerListScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: SafeArea(
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) =>
              setState(() => _currentIndex = index),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          indicatorColor: AppColors.primary.withOpacity(0.15),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.shield_outlined),
              selectedIcon: Icon(Icons.shield, color: AppColors.primary),
              label: '首页',
            ),
            NavigationDestination(
              icon: Icon(Icons.dns_outlined),
              selectedIcon: Icon(Icons.dns, color: AppColors.primary),
              label: '服务器',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings, color: AppColors.primary),
              label: '设置',
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildTopBar(context),
            const SizedBox(height: 32),
            // VPN错误提示
            Consumer<VpnProvider>(
              builder: (context, vpn, _) {
                if (vpn.status == VpnStatus.error && vpn.errorMessage.isNotEmpty) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '连接失败',
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: AppColors.error, size: 18),
                              onPressed: () {
                                // 清除错误状态
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          vpn.errorMessage,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            _showDiagnosticDialog(context);
                          },
                          icon: const Icon(Icons.bug_report, size: 16),
                          label: const Text('查看诊断信息'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const StatusCard(),
            const SizedBox(height: 32),
            const ConnectButton(),
            const SizedBox(height: 32),
            const TrafficCard(),
            const SizedBox(height: 20),
            const ServerSelectorCard(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Logo + 名称
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bolt, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              '速连VPN',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        // 刷新按钮
        Consumer<ServerProvider>(
          builder: (context, serverProvider, _) {
            return IconButton(
              icon: serverProvider.updateStatus == UpdateStatus.loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.textSecondary,
                    ),
              onPressed: serverProvider.updateStatus == UpdateStatus.loading
                  ? null
                  : () => serverProvider.refreshSubscription(),
            );
          },
        ),
      ],
    );
  }

  void _showDiagnosticDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.bug_report, color: AppColors.primary),
            SizedBox(width: 8),
            Text('VPN连接诊断'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '如果VPN无法连接，请检查以下事项：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildCheckItem('1. v2ray核心是否正确安装'),
              _buildCheckItem('   - 查看构建日志确认v2ray下载成功'),
              _buildCheckItem('   - APK中应包含 libv2ray.so 文件'),
              const SizedBox(height: 8),
              _buildCheckItem('2. 订阅地址是否有效'),
              _buildCheckItem('   - 在设置中检查订阅URL'),
              _buildCheckItem('   - 点击刷新按钮测试订阅'),
              const SizedBox(height: 8),
              _buildCheckItem('3. 节点是否可用'),
              _buildCheckItem('   - 尝试切换其他节点'),
              _buildCheckItem('   - 检查网络连接'),
              const SizedBox(height: 8),
              _buildCheckItem('4. 权限是否授予'),
              _buildCheckItem('   - 确认已授予VPN权限'),
              _buildCheckItem('   - 检查是否有后台运行权限'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Text(
                  '💡 提示：如果是首次使用，请确保从GitHub Actions下载的APK包含了v2ray核心。',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

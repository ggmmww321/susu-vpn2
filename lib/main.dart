import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/providers/vpn_provider.dart';
import 'core/providers/server_provider.dart';
import 'core/providers/settings_provider.dart';
import 'features/home/home_screen.dart';
import 'models/server_node.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 设置状态栏透明
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // 锁定竖屏（可根据设备类型判断）
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // 初始化本地存储
  await Hive.initFlutter();
  Hive.registerAdapter(ServerNodeAdapter());
  Hive.registerAdapter(ServerProtocolAdapter());
  await Hive.openBox<ServerNode>('servers');
  await Hive.openBox('settings');

  runApp(const SusuVPNApp());
}

class SusuVPNApp extends StatelessWidget {
  const SusuVPNApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ServerProvider()),
        ChangeNotifierProvider(create: (_) => VpnProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: '速连VPN',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}

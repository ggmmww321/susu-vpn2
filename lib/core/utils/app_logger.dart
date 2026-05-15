import 'package:logger/logger.dart';

/// 应用日志管理器
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  /// 调试日志
  static void d(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// 信息日志
  static void i(String message) {
    _logger.i(message);
  }

  /// 警告日志
  static void w(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// 错误日志
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// VPN相关日志
  static void vpn(String message) {
    _logger.i('🔌 VPN: $message');
  }

  /// 订阅相关日志
  static void subscription(String message) {
    _logger.i('📡 Subscription: $message');
  }

  /// 节点相关日志
  static void node(String message) {
    _logger.i('🌐 Node: $message');
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsProvider extends ChangeNotifier {
  late Box _box;

  bool _bypassCN = true;
  bool _enableUDP = true;
  bool _autoReconnect = true;
  ThemeMode _themeMode = ThemeMode.dark;
  int _localSocksPort = 10808;
  int _localHttpPort = 10809;
  String _dnsServer = '8.8.8.8';

  bool get bypassCN => _bypassCN;
  bool get enableUDP => _enableUDP;
  bool get autoReconnect => _autoReconnect;
  ThemeMode get themeMode => _themeMode;
  int get localSocksPort => _localSocksPort;
  int get localHttpPort => _localHttpPort;
  String get dnsServer => _dnsServer;

  SettingsProvider() {
    _box = Hive.box('settings');
    _loadSettings();
  }

  void _loadSettings() {
    _bypassCN = _box.get('bypassCN', defaultValue: true);
    _enableUDP = _box.get('enableUDP', defaultValue: true);
    _autoReconnect = _box.get('autoReconnect', defaultValue: true);
    _localSocksPort = _box.get('localSocksPort', defaultValue: 10808);
    _localHttpPort = _box.get('localHttpPort', defaultValue: 10809);
    _dnsServer = _box.get('dnsServer', defaultValue: '8.8.8.8');

    String themeModeStr = _box.get('themeMode', defaultValue: 'dark');
    switch (themeModeStr) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'system':
        _themeMode = ThemeMode.system;
        break;
      default:
        _themeMode = ThemeMode.dark;
    }
  }

  Future<void> setBypassCN(bool value) async {
    _bypassCN = value;
    await _box.put('bypassCN', value);
    notifyListeners();
  }

  Future<void> setEnableUDP(bool value) async {
    _enableUDP = value;
    await _box.put('enableUDP', value);
    notifyListeners();
  }

  Future<void> setAutoReconnect(bool value) async {
    _autoReconnect = value;
    await _box.put('autoReconnect', value);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    String modeStr;
    switch (mode) {
      case ThemeMode.light:
        modeStr = 'light';
        break;
      case ThemeMode.system:
        modeStr = 'system';
        break;
      default:
        modeStr = 'dark';
    }
    await _box.put('themeMode', modeStr);
    notifyListeners();
  }

  Future<void> setLocalSocksPort(int port) async {
    _localSocksPort = port;
    await _box.put('localSocksPort', port);
    notifyListeners();
  }

  Future<void> setLocalHttpPort(int port) async {
    _localHttpPort = port;
    await _box.put('localHttpPort', port);
    notifyListeners();
  }

  Future<void> setDnsServer(String dns) async {
    _dnsServer = dns;
    await _box.put('dnsServer', dns);
    notifyListeners();
  }
}

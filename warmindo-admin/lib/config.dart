import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

/// Server configuration for Warmindo Admin
/// IP bisa diubah dari app tanpa perlu compile ulang
class AppConfig {
  // Default IP (dipakai pertama kali)
  static const String _defaultIp = '192.168.1.86';
  static const int serverPort = 8000;

  // Runtime IP — bisa diubah dari settings
  static String _serverIp = _defaultIp;

  /// Current server IP
  static String get serverIp => _serverIp;

  /// Load saved IP from storage (panggil di main.dart saat startup)
  static Future<void> loadSavedIp() async {
    if (kIsWeb) return; // Web selalu pakai localhost
    final prefs = await SharedPreferences.getInstance();
    _serverIp = prefs.getString('server_ip') ?? _defaultIp;
  }

  /// Save new IP (dipanggil dari settings dialog)
  static Future<void> setServerIp(String ip) async {
    _serverIp = ip;
    if (!kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_ip', ip);
    }
  }

  /// Base API URL
  static String get apiBaseUrl {
    if (kIsWeb) return 'http://localhost:$serverPort/api';
    return 'http://$_serverIp:$serverPort/api';
  }

  /// Socket.IO URL
  static String get socketUrl {
    if (kIsWeb) return 'http://localhost:$serverPort';
    return 'http://$_serverIp:$serverPort';
  }
}

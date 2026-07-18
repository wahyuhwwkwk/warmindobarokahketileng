import 'dart:io' show Platform;
import 'dart:ui' show Color;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service untuk menampilkan local notification dengan sound & vibration
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Notification channel ID untuk pesanan baru
  static const String _channelId = 'warmindo_new_order';
  static const String _channelName = 'Pesanan Baru';
  static const String _channelDescription =
      'Notifikasi saat ada pesanan baru masuk';

  /// Initialize notification plugin dan channel
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Android initialization
    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_launcher_foreground');

    // iOS initialization (fallback)
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channel with HIGH importance
    await _createNotificationChannel();

    _isInitialized = true;
    debugPrint('🔔 NotificationService initialized');
  }

  /// Create high-priority notification channel
  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Request notification permission (required for Android 13+)
  Future<bool> requestPermission() async {
    if (kIsWeb) return true;

    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      debugPrint('🔔 Notification permission: $status');
      return status.isGranted;
    }
    return true;
  }

  /// Handle notification tap — bisa digunakan untuk navigasi
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
    // App akan terbuka otomatis karena launchMode=singleTop
  }

  /// Tampilkan notifikasi pesanan baru
  Future<void> showNewOrderNotification({
    required String orderNumber,
    required String tableNumber,
    String? customerName,
  }) async {
    if (!_isInitialized) await initialize();

    // Vibration pattern: wait 0ms, vibrate 300ms, wait 200ms, vibrate 500ms, wait 200ms, vibrate 300ms
    final vibrationPattern =
        Int64List.fromList([0, 300, 200, 500, 200, 300]);

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      // Heads-up notification (pop-up di atas layar)
      fullScreenIntent: true,
      // Sound
      playSound: true,
      // Vibration
      enableVibration: true,
      vibrationPattern: vibrationPattern,
      // Visual
      enableLights: true,
      color: const Color(0xFFF97316),
      icon: '@drawable/ic_launcher_foreground',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      // Style — expanded notification content
      styleInformation: BigTextStyleInformation(
        customerName != null
            ? '📋 $orderNumber\n👤 $customerName\n🪑 Meja $tableNumber'
            : '📋 $orderNumber\n🪑 Meja $tableNumber',
        contentTitle: '🔔 Pesanan Baru Masuk!',
        summaryText: 'Warmindo Admin',
      ),
      // Auto-cancel when tapped
      autoCancel: true,
      // Show timestamp
      showWhen: true,
      // Category
      category: AndroidNotificationCategory.message,
    );

    // Use timestamp as unique notification ID
    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _notifications.show(
      notificationId,
      '🔔 Pesanan Baru Masuk!',
      '$orderNumber — Meja $tableNumber',
      NotificationDetails(android: androidDetails),
      payload: orderNumber,
    );

    debugPrint('🔔 Notification shown for $orderNumber');
  }
}

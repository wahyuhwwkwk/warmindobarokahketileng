import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config.dart';
import 'notification_service.dart';

/// Background service yang menjaga koneksi Socket.IO tetap hidup
/// dan menampilkan notifikasi saat ada pesanan baru
class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  final FlutterBackgroundService _service = FlutterBackgroundService();

  /// Notification channel untuk foreground service (persistent notification)
  static const String _serviceChannelId = 'warmindo_bg_service';
  static const String _serviceChannelName = 'Warmindo Service';

  /// Initialize dan start background service
  Future<void> initialize() async {
    // Create notification channel for the foreground service
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _serviceChannelId,
            _serviceChannelName,
            description: 'Menjaga koneksi untuk menerima pesanan baru',
            importance: Importance.low, // Low importance = no sound for persistent notif
            showBadge: false,
          ),
        );

    await _service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: true,
        autoStartOnBoot: true,
        isForegroundMode: true,
        foregroundServiceTypes: [AndroidForegroundType.specialUse],
        notificationChannelId: _serviceChannelId,
        initialNotificationTitle: 'Warmindo Admin',
        initialNotificationContent: 'Menunggu pesanan baru...',
        foregroundServiceNotificationId: 888,
      ),
    );

    debugPrint('🔧 BackgroundService configured');
  }

  /// Start the service
  Future<void> start() async {
    final isRunning = await _service.isRunning();
    if (!isRunning) {
      await _service.startService();
      debugPrint('🚀 BackgroundService started');
    } else {
      debugPrint('✅ BackgroundService already running');
    }
  }

  /// Send the current server IP to the background service
  Future<void> updateServerIp(String ip) async {
    _service.invoke('updateIp', {'ip': ip});
  }
}

// ============================================================
// BACKGROUND SERVICE ENTRY POINTS
// These run in a separate isolate!
// ============================================================

/// iOS background handler
@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}

/// Main background service entry point
@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  IO.Socket? socket;

  // Initialize notification service in background isolate
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Get server IP — use the default from config initially
  String serverIp = AppConfig.serverIp;
  int serverPort = AppConfig.serverPort;

  /// Connect socket in background
  void connectSocket() {
    final serverUrl = 'http://$serverIp:$serverPort';
    debugPrint('🔌 [BG] Connecting to socket: $serverUrl');

    socket?.disconnect();
    socket?.dispose();

    socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionDelay': 2000,
      'reconnectionAttempts': 9999,
    });

    socket!.onConnect((_) {
      debugPrint('✅ [BG] Socket connected');
      socket!.emit('join_admin');

      // Update foreground notification
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Warmindo Admin',
          content: '✅ Terhubung — Menunggu pesanan...',
        );
      }
    });

    socket!.onDisconnect((_) {
      debugPrint('❌ [BG] Socket disconnected');
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Warmindo Admin',
          content: '⚠️ Terputus — Mencoba menghubungkan ulang...',
        );
      }
    });

    socket!.onConnectError((data) {
      debugPrint('⚠️ [BG] Socket error: $data');
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Warmindo Admin',
          content: '⚠️ Gagal terhubung — Retry otomatis...',
        );
      }
    });

    // Listen for new orders — trigger notification
    socket!.on('order:new', (data) async {
      debugPrint('🆕 [BG] New order received!');
      try {
        final orderNumber = data['orderNumber'] ?? 'Unknown';
        final table = data['table'];
        final tableNumber = table != null ? table['number']?.toString() ?? '-' : '-';
        final customerName = data['customerName'];

        await notificationService.showNewOrderNotification(
          orderNumber: orderNumber,
          tableNumber: tableNumber,
          customerName: customerName,
        );

        // Notify foreground app (if running)
        service.invoke('onNewOrder', data);
      } catch (e) {
        debugPrint('❌ [BG] Error handling new order: $e');
      }
    });

    // Listen for order updates
    socket!.on('order:updated', (data) {
      debugPrint('📝 [BG] Order updated');
      service.invoke('onOrderUpdated', data);
    });
  }

  // Listen for IP updates from foreground
  service.on('updateIp').listen((event) {
    if (event != null && event['ip'] != null) {
      serverIp = event['ip'];
      debugPrint('🔄 [BG] Server IP updated to: $serverIp');
      connectSocket();
    }
  });

  // Listen for stop command
  service.on('stopService').listen((event) {
    debugPrint('🛑 [BG] Service stopping');
    socket?.disconnect();
    socket?.dispose();
    service.stopSelf();
  });

  // Start socket connection
  connectSocket();

  // Heartbeat to keep service alive
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        // Keep alive
        final isConnected = socket?.connected ?? false;
        if (!isConnected) {
          debugPrint('💔 [BG] Socket not connected, reconnecting...');
          connectSocket();
        }
      }
    }
  });
}

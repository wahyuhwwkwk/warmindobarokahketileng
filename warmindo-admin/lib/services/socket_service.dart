import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/order_model.dart';
import '../config.dart';

class SocketService {
  static SocketService? _instance;
  late IO.Socket socket;
  bool _isConnected = false;

  // Callbacks
  Function(OrderModel)? onNewOrder;
  Function(OrderModel)? onOrderUpdated;
  Function(String)? onOrderExpired;
  Function(bool)? onConnectionChange;

  SocketService._internal();

  factory SocketService() {
    _instance ??= SocketService._internal();
    return _instance!;
  }

  bool get isConnected => _isConnected;

  void connect() {
    final serverUrl = AppConfig.socketUrl;

    socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionDelay': 1000,
      'reconnectionAttempts': 100,
    });

    socket.onConnect((_) {
      print('✅ Socket.IO connected');
      _isConnected = true;
      onConnectionChange?.call(true);

      // Join admin room to receive all order events
      socket.emit('join_admin');
    });

    socket.onDisconnect((_) {
      print('❌ Socket.IO disconnected');
      _isConnected = false;
      onConnectionChange?.call(false);
    });

    socket.onConnectError((data) {
      print('⚠️ Socket.IO connection error: $data');
      _isConnected = false;
      onConnectionChange?.call(false);
    });

    // Listen for new orders from customers
    socket.on('order:new', (data) {
      print('🆕 New order received!');
      try {
        final order = OrderModel.fromJson(data);
        onNewOrder?.call(order);
      } catch (e) {
        print('Error parsing new order: $e');
      }
    });

    // Listen for order status updates
    socket.on('order:updated', (data) {
      print('📝 Order updated');
      try {
        final order = OrderModel.fromJson(data);
        onOrderUpdated?.call(order);
      } catch (e) {
        print('Error parsing updated order: $e');
      }
    });

    // Listen for expired orders (auto-deleted after 5 min unpaid)
    socket.on('order:expired', (data) {
      print('⏰ Order expired: ${data['orderNumber']}');
      try {
        final orderId = data['id'] as String;
        onOrderExpired?.call(orderId);
      } catch (e) {
        print('Error parsing expired order: $e');
      }
    });
  }

  void disconnect() {
    socket.disconnect();
    socket.dispose();
    _isConnected = false;
  }
}

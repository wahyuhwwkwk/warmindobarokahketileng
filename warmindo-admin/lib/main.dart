import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config.dart';
import 'models/order_model.dart';
import 'services/api_service.dart';
import 'services/socket_service.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/banner_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await AppConfig.loadSavedIp();

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermission();

  // Initialize background service
  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
    final backgroundService = BackgroundService();
    await backgroundService.initialize();
  }

  runApp(const WarmindoAdminApp());
}

class WarmindoAdminApp extends StatelessWidget {
  const WarmindoAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Warmindo Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF97316),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        useMaterial3: true,
      ),
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _isLoggedIn = false;

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return LoginScreen(
        onLoginSuccess: () => setState(() => _isLoggedIn = true),
      );
    }
    return const AdminShell();
  }
}

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;
  List<OrderModel> _orders = [];
  bool _isConnected = false;
  final SocketService _socketService = SocketService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _initSocket();
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      _initBackgroundServiceListener();
      _startBackgroundService();
    }
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }

  /// Start the background service and send current server IP
  void _startBackgroundService() async {
    final bgService = BackgroundService();
    await bgService.start();
    await bgService.updateServerIp(AppConfig.serverIp);
  }

  /// Listen for events from background service (new orders, updates)
  void _initBackgroundServiceListener() {
    final service = FlutterBackgroundService();

    // When background service detects new order
    service.on('onNewOrder').listen((data) {
      if (data != null && mounted) {
        try {
          final order = OrderModel.fromJson(Map<String, dynamic>.from(data));
          // Check if order already exists (avoid duplicates from foreground socket)
          final exists = _orders.any((o) => o.id == order.id);
          if (!exists) {
            setState(() {
              _orders.insert(0, order);
            });
            _showInAppNotification(order);
          }
        } catch (e) {
          debugPrint('Error handling bg order: $e');
        }
      }
    });

    // When background service detects order update
    service.on('onOrderUpdated').listen((data) {
      if (data != null && mounted) {
        try {
          final updatedOrder = OrderModel.fromJson(Map<String, dynamic>.from(data));
          setState(() {
            final idx = _orders.indexWhere((o) => o.id == updatedOrder.id);
            if (idx != -1) {
              _orders[idx] = updatedOrder;
            }
          });
        } catch (e) {
          debugPrint('Error handling bg order update: $e');
        }
      }
    });
  }

  void _initSocket() {
    _socketService.onConnectionChange = (connected) {
      if (mounted) setState(() => _isConnected = connected);
    };

    _socketService.onNewOrder = (order) {
      if (mounted) {
        // Check if order already exists (may have been added by background service)
        final exists = _orders.any((o) => o.id == order.id);
        if (!exists) {
          setState(() {
            _orders.insert(0, order);
          });
        }

        // Show notification (foreground — local notification with sound + vibration)
        _notificationService.showNewOrderNotification(
          orderNumber: order.orderNumber,
          tableNumber: order.tableNumberStr,
          customerName: order.customerName,
        );

        // Show in-app snackbar
        _showInAppNotification(order);

        // Auto-switch to orders tab if on dashboard
        if (_currentIndex == 0) {
          setState(() => _currentIndex = 1);
        }
      }
    };

    _socketService.onOrderUpdated = (updatedOrder) {
      if (mounted) {
        setState(() {
          final idx = _orders.indexWhere((o) => o.id == updatedOrder.id);
          if (idx != -1) {
            _orders[idx] = updatedOrder;
          }
        });
      }
    };

    _socketService.onOrderExpired = (orderId) {
      if (mounted) {
        setState(() {
          _orders.removeWhere((o) => o.id == orderId);
        });
      }
    };

    _socketService.connect();
  }

  /// Show in-app SnackBar notification
  void _showInAppNotification(OrderModel order) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('🔔  ', style: TextStyle(fontSize: 18)),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pesanan Baru!', style: TextStyle(fontWeight: FontWeight.w700)),
                  Text(
                    '${order.orderNumber} — Meja ${order.tableNumberStr}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await ApiService.getOrders();
      if (mounted) {
        setState(() => _orders = orders);
      }
    } catch (e) {
      print('Error loading orders: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar (Desktop/Tablet)
          if (isWide)
            NavigationRail(
              extended: MediaQuery.of(context).size.width > 1100,
              minExtendedWidth: 220,
              backgroundColor: const Color(0xFF0F172A),
              selectedIndex: _currentIndex,
              onDestinationSelected: (i) => setState(() => _currentIndex = i),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.restaurant_menu_rounded, color: Color(0xFFF97316), size: 26),
                        if (MediaQuery.of(context).size.width > 1100) ...[
                          const SizedBox(width: 10),
                          const Text(
                            'Admin Barokah',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isConnected ? const Color(0xFF22C55E) : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isConnected ? 'Terhubung' : 'Offline',
                          style: TextStyle(
                            color: _isConnected ? Colors.grey.shade400 : Colors.red.shade300,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              selectedIconTheme: const IconThemeData(color: Colors.white),
              unselectedIconTheme: IconThemeData(color: Colors.grey.shade500),
              selectedLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              unselectedLabelTextStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              indicatorColor: const Color(0xFFF97316),
              destinations: [
                const NavigationRailDestination(
                  icon: Icon(Icons.dashboard_rounded),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Badge(
                    isLabelVisible: _orders.where((o) => o.isActive).isNotEmpty,
                    label: Text('${_orders.where((o) => o.isActive).length}'),
                    backgroundColor: const Color(0xFFF97316),
                    child: const Icon(Icons.receipt_long_rounded),
                  ),
                  label: const Text('Pesanan'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.restaurant_rounded),
                  label: Text('Menu'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.photo_library_rounded),
                  label: Text('Banner'),
                ),
              ],
            ),

          // Main Content
          Expanded(
            child: SafeArea(
              bottom: false,
              left: false,
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  DashboardScreen(orders: _orders),
                  OrdersScreen(orders: _orders, onRefresh: _loadOrders),
                  const MenuScreen(),
                  const BannerScreen(),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Navigation (Mobile)
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              height: 65,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              indicatorColor: const Color(0xFFFFF7ED),
              selectedIndex: _currentIndex,
              onDestinationSelected: (i) => setState(() => _currentIndex = i),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded, color: Color(0xFFF97316)),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: _orders.where((o) => o.isActive).isNotEmpty,
                    label: Text('${_orders.where((o) => o.isActive).length}',
                      style: const TextStyle(fontSize: 10)),
                    backgroundColor: const Color(0xFFF97316),
                    child: const Icon(Icons.receipt_long_outlined),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: _orders.where((o) => o.isActive).isNotEmpty,
                    label: Text('${_orders.where((o) => o.isActive).length}',
                      style: const TextStyle(fontSize: 10)),
                    backgroundColor: const Color(0xFFF97316),
                    child: const Icon(Icons.receipt_long_rounded, color: Color(0xFFF97316)),
                  ),
                  label: 'Pesanan',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.restaurant_outlined),
                  selectedIcon: Icon(Icons.restaurant_rounded, color: Color(0xFFF97316)),
                  label: 'Menu',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.photo_library_outlined),
                  selectedIcon: Icon(Icons.photo_library_rounded, color: Color(0xFFF97316)),
                  label: 'Banner',
                ),
              ],
            ),
    );
  }
}

import 'menu_model.dart';

class OrderItem {
  final String id;
  final String menuId;
  final int quantity;
  final double price;
  final String? variantName;
  final String? notes;
  final MenuModel? menu;

  OrderItem({
    required this.id,
    required this.menuId,
    required this.quantity,
    required this.price,
    this.variantName,
    this.notes,
    this.menu,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? '',
      menuId: json['menuId'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] is String) ? double.tryParse(json['price']) ?? 0 : (json['price'] as num).toDouble(),
      variantName: json['variantName'],
      notes: json['notes'],
      menu: json['menu'] != null ? MenuModel.fromJson(json['menu']) : null,
    );
  }
}

class OrderTable {
  final String id;
  final int number;

  OrderTable({required this.id, required this.number});

  factory OrderTable.fromJson(Map<String, dynamic> json) {
    return OrderTable(
      id: json['id'] ?? '',
      number: json['number'] ?? 0,
    );
  }
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String? tableId;
  final OrderTable? table;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final String paymentMethod;
  final String? customerName;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.orderNumber,
    this.tableId,
    this.table,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    this.customerName,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      tableId: json['tableId'],
      table: json['table'] != null ? OrderTable.fromJson(json['table']) : null,
      items: (json['items'] as List<dynamic>?)?.map((e) => OrderItem.fromJson(e)).toList() ?? [],
      totalAmount: (json['totalAmount'] is String)
          ? double.tryParse(json['totalAmount']) ?? 0
          : (json['totalAmount'] as num).toDouble(),
      status: json['status'] ?? 'WAITING_PAYMENT',
      paymentMethod: json['paymentMethod'] ?? 'CASH',
      customerName: json['customerName'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  String get tableNumberStr => table?.number.toString() ?? '-';

  bool get isActive => ['PAID', 'PROCESSING', 'READY', 'WAITING_PAYMENT'].contains(status);
}

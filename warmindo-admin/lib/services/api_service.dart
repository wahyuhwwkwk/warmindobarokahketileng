import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/menu_model.dart';
import '../models/order_model.dart';
import '../config.dart';

class ApiService {
  static String _getBaseUrl() {
    return AppConfig.apiBaseUrl;
  }

  // ==========================================
  // AUTH
  // ==========================================
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('${_getBaseUrl()}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    final errorData = json.decode(response.body);
    throw Exception(errorData['error'] ?? 'Login gagal');
  }

  // ==========================================
  // CATEGORIES
  // ==========================================
  static Future<List<Category>> getCategories() async {
    final response = await http.get(Uri.parse('${_getBaseUrl()}/categories'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Category.fromJson(e)).toList();
    }
    throw Exception('Failed to load categories');
  }

  // ==========================================
  // MENUS
  // ==========================================
  static Future<List<MenuModel>> getAllMenus() async {
    final response = await http.get(Uri.parse('${_getBaseUrl()}/menus/all'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => MenuModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load menus');
  }

  static Future<MenuModel> createMenu(Map<String, dynamic> menuData) async {
    final response = await http.post(
      Uri.parse('${_getBaseUrl()}/menus'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(menuData),
    );
    if (response.statusCode == 200) {
      return MenuModel.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to create menu');
  }

  /// Upload menu image file to backend, returns the image URL path
  static Future<String> uploadMenuImage(List<int> bytes, String filename) async {
    final uri = Uri.parse('${_getBaseUrl()}/menus/upload-image');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: filename));
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['imageUrl'] as String;
    }
    throw Exception('Failed to upload menu image');
  }

  static Future<MenuModel> updateMenu(String id, Map<String, dynamic> menuData) async {
    final response = await http.put(
      Uri.parse('${_getBaseUrl()}/menus/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(menuData),
    );
    if (response.statusCode == 200) {
      return MenuModel.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to update menu');
  }

  static Future<void> toggleMenu(String id) async {
    final response = await http.put(Uri.parse('${_getBaseUrl()}/menus/$id/toggle'));
    if (response.statusCode != 200) {
      throw Exception('Failed to toggle menu');
    }
  }

  static Future<void> toggleFavorite(String id) async {
    final response = await http.put(Uri.parse('${_getBaseUrl()}/menus/$id/favorite'));
    if (response.statusCode != 200) {
      throw Exception('Failed to toggle favorite');
    }
  }

  static Future<void> deleteMenu(String id) async {
    final response = await http.delete(Uri.parse('${_getBaseUrl()}/menus/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete menu');
    }
  }

  // ==========================================
  // ORDERS
  // ==========================================
  static Future<List<OrderModel>> getOrders() async {
    final response = await http.get(Uri.parse('${_getBaseUrl()}/orders'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => OrderModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load orders');
  }

  static Future<OrderModel> updateOrderStatus(String id, String status) async {
    final response = await http.put(
      Uri.parse('${_getBaseUrl()}/orders/$id/status'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'status': status}),
    );
    if (response.statusCode == 200) {
      return OrderModel.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to update order status');
  }

  // ==========================================
  // DASHBOARD
  // ==========================================
  static Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await http.get(Uri.parse('${_getBaseUrl()}/dashboard/stats'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load dashboard stats');
  }

  // ==========================================
  // EXPORT CSV
  // ==========================================
  static Future<String> exportCsv() async {
    final response = await http.get(Uri.parse('${_getBaseUrl()}/orders/export/csv'));
    if (response.statusCode == 200) {
      return response.body;
    }
    throw Exception('Failed to export CSV');
  }
}

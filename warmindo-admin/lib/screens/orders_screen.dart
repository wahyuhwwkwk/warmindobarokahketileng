import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../widgets/order_card.dart';

class OrdersScreen extends StatefulWidget {
  final List<OrderModel> orders;
  final Function() onRefresh;

  const OrdersScreen({
    super.key,
    required this.orders,
    required this.onRefresh,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // Filter by search query
    final filtered = widget.orders.where((o) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final nameMatch = o.customerName?.toLowerCase().contains(query) ?? false;
      final orderMatch = o.orderNumber.toLowerCase().contains(query);
      return nameMatch || orderMatch;
    }).toList();

    // Sort: active first, then newest
    final sorted = List<OrderModel>.from(filtered)..sort((a, b) {
      const activeStatuses = ['PAID', 'PROCESSING', 'READY', 'WAITING_PAYMENT'];
      final aActive = activeStatuses.contains(a.status) ? 1 : 0;
      final bActive = activeStatuses.contains(b.status) ? 1 : 0;
      if (aActive != bActive) return bActive - aActive;
      return b.createdAt.compareTo(a.createdAt);
    });

    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      color: const Color(0xFF16A34A),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manajemen Pesanan',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kelola order dari pelanggan secara realtime. (${sorted.length} pesanan)',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 14),

                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Cari nama customer atau order ID...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                        prefixIcon: Icon(Icons.search_rounded, size: 20, color: Colors.grey.shade400),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade400),
                                onPressed: () => setState(() => _searchQuery = ''),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),

                  // Search result info
                  if (_searchQuery.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Hasil pencarian "$_searchQuery": ${sorted.length} pesanan ditemukan',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Empty state
          if (sorted.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.receipt_long_rounded,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'Tidak ada pesanan yang cocok.'
                          : 'Belum ada order masuk.',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                    ),
                    if (_searchQuery.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => setState(() => _searchQuery = ''),
                        child: const Text(
                          'Hapus pencarian',
                          style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            // Use SliverList instead of SliverGrid to avoid fixed height issues
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.crossAxisExtent;
                  // Determine columns based on available width
                  int columns = 1;
                  if (width > 1200) {
                    columns = 3;
                  } else if (width > 700) {
                    columns = 2;
                  }

                  // Build rows of cards
                  final rows = <List<OrderModel>>[];
                  for (int i = 0; i < sorted.length; i += columns) {
                    rows.add(sorted.sublist(i, (i + columns) > sorted.length ? sorted.length : i + columns));
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final row = rows[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (int i = 0; i < columns; i++) ...[
                                if (i > 0) const SizedBox(width: 16),
                                Expanded(
                                  child: i < row.length
                                      ? OrderCard(
                                          order: row[i],
                                          onUpdateStatus: (status) async {
                                            try {
                                              await ApiService.updateOrderStatus(row[i].id, status);
                                              widget.onRefresh();
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: const Text('Gagal update status'),
                                                    backgroundColor: Colors.red,
                                                    behavior: SnackBarBehavior.floating,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                        )
                                      : const SizedBox(), // Empty placeholder for incomplete row
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                      childCount: rows.length,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

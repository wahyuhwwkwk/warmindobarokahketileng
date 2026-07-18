import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:printing/printing.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/revenue_chart.dart';

final _rpFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
final _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'id_ID');

class DashboardScreen extends StatefulWidget {
  final List<OrderModel> orders;

  const DashboardScreen({super.key, required this.orders});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = DateTime(now.year, now.month, now.day);
  }

  /// Whether the range covers only a single day
  bool get _isSingleDay =>
      _startDate.year == _endDate.year &&
      _startDate.month == _endDate.month &&
      _startDate.day == _endDate.day;

  /// Whether the range is just today
  bool get _isTodayOnly {
    final now = DateTime.now();
    return _isSingleDay &&
        _startDate.year == now.year &&
        _startDate.month == now.month &&
        _startDate.day == now.day;
  }

  List<OrderModel> get _filteredOrders {
    final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final end = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59, 999);
    return widget.orders.where((o) {
      return !o.createdAt.isBefore(start) && !o.createdAt.isAfter(end);
    }).toList();
  }

  double get _totalRevenue {
    return _filteredOrders
        .where((o) => o.status != 'CANCELLED' && o.status != 'WAITING_PAYMENT')
        .fold(0.0, (sum, o) => sum + o.totalAmount);
  }

  int get _completedOrders => _filteredOrders.where((o) => o.status == 'COMPLETED').length;
  int get _activeOrders => _filteredOrders.where((o) => ['PAID', 'PROCESSING', 'READY'].contains(o.status)).length;

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      helpText: 'Pilih tanggal mulai',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFF97316),
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // If start date is after end date, auto-adjust end date
        if (_startDate.isAfter(_endDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
      helpText: 'Pilih tanggal akhir',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFF97316),
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _exportAndDownload() async {
    setState(() => _exporting = true);
    try {
      final orders = _filteredOrders;
      if (orders.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Tidak ada data untuk di-export'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        return;
      }

      // Build CSV content
      final buffer = StringBuffer();
      buffer.writeln('No,Order ID,Meja,Nama Customer,Waktu,Items,Total Tagihan,Status,Metode Bayar');
      for (int i = 0; i < orders.length; i++) {
        final o = orders[i];
        final items = o.items.map((item) => '${item.quantity}x ${item.menu?.name ?? "Menu"}').join('; ');
        buffer.writeln('${i + 1},${o.orderNumber},${o.tableNumberStr},${o.customerName ?? '-'},${_dateTimeFormat.format(o.createdAt)},"$items",${o.totalAmount},${o.status},${o.paymentMethod}');
      }

      // Export via printing package (works on web + mobile)
      final csvBytes = utf8.encode(buffer.toString());
      final fmtDate = DateFormat('yyyy-MM-dd');
      final fileName = _isSingleDay
          ? 'Laporan_Penjualan_${fmtDate.format(_startDate)}.csv'
          : 'Laporan_Penjualan_${fmtDate.format(_startDate)}_sd_${fmtDate.format(_endDate)}.csv';

      await Printing.sharePdf(
        bytes: csvBytes,
        filename: fileName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('$fileName berhasil di-download! (${orders.length} pesanan)')),
              ],
            ),
            backgroundColor: const Color(0xFFF97316),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal export: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String get _overviewTitle {
    if (_isTodayOnly) return 'Overview Hari Ini';
    if (_isSingleDay) return 'Overview ${_dateFormat.format(_startDate)}';
    return 'Overview ${_dateFormat.format(_startDate)} - ${_dateFormat.format(_endDate)}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return RefreshIndicator(
      onRefresh: () async {},
      color: const Color(0xFFF97316),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              _overviewTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pantau performa resto Anda secara realtime.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),

            // Date Range Filter + Export Row
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Start Date Picker
                _datePickerButton(
                  label: 'Dari',
                  date: _startDate,
                  onTap: _pickStartDate,
                ),

                // Arrow icon
                Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.grey.shade400),

                // End Date Picker
                _datePickerButton(
                  label: 'Sampai',
                  date: _endDate,
                  onTap: _pickEndDate,
                ),

                // Quick "Hari Ini" button (only if not already today-only)
                if (!_isTodayOnly)
                  _quickDateBtn('Hari Ini', () {
                    final now = DateTime.now();
                    setState(() {
                      _startDate = DateTime(now.year, now.month, now.day);
                      _endDate = DateTime(now.year, now.month, now.day);
                    });
                  }),

                // Export CSV button
                ElevatedButton.icon(
                  onPressed: _exporting ? null : _exportAndDownload,
                  icon: _exporting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download_rounded, size: 16),
                  label: Text(_exporting ? 'Exporting...' : 'Download CSV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Stats Grid — responsive
            LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth > 800 ? 4 : 2;
                final spacing = 12.0;
                final cardWidth = (constraints.maxWidth - (spacing * (cols - 1))) / cols;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: StatCard(
                        title: 'Pendapatan',
                        value: _rpFormat.format(_totalRevenue),
                        icon: Icons.attach_money_rounded,
                        color: const Color(0xFFF97316),
                        bgColor: const Color(0xFFFFF7ED),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: StatCard(
                        title: 'Pesanan Selesai',
                        value: '$_completedOrders',
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF2563EB),
                        bgColor: const Color(0xFFDBEAFE),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: StatCard(
                        title: 'Pesanan Aktif',
                        value: '$_activeOrders',
                        icon: Icons.restaurant_rounded,
                        color: const Color(0xFFD97706),
                        bgColor: const Color(0xFFFEF3C7),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: StatCard(
                        title: 'Total Pesanan',
                        value: '${_filteredOrders.length}',
                        icon: Icons.receipt_long_rounded,
                        color: const Color(0xFF7C3AED),
                        bgColor: const Color(0xFFF3E8FF),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Revenue Chart
            RevenueChart(orders: _filteredOrders, isTodayOnly: _isTodayOnly),
            const SizedBox(height: 24),

            // Recent Orders Table
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(Icons.access_time_rounded, color: Colors.grey.shade400, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Pesanan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_filteredOrders.length} pesanan',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_filteredOrders.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            Text(
                              _isSingleDay
                                  ? 'Belum ada pesanan pada tanggal ini.'
                                  : 'Belum ada pesanan pada rentang tanggal ini.',
                              style: TextStyle(color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: screenWidth > 600 ? screenWidth - 300 : screenWidth - 40),
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                          headingTextStyle: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                          dataTextStyle: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                          columnSpacing: 20,
                          columns: const [
                            DataColumn(label: Text('Order ID')),
                            DataColumn(label: Text('Meja')),
                            DataColumn(label: Text('Customer')),
                            DataColumn(label: Text('Waktu')),
                            DataColumn(label: Text('Total')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Bayar')),
                          ],
                          rows: _filteredOrders.map((o) {
                            return DataRow(cells: [
                              DataCell(Text(
                                o.orderNumber,
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                              )),
                              DataCell(Text(o.tableNumberStr, style: const TextStyle(fontWeight: FontWeight.w700))),
                              DataCell(Text(
                                o.customerName ?? '-',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
                              )),
                              DataCell(Text(
                                _isSingleDay
                                    ? DateFormat('HH:mm').format(o.createdAt)
                                    : _dateTimeFormat.format(o.createdAt),
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              )),
                              DataCell(Text(_rpFormat.format(o.totalAmount))),
                              DataCell(StatusBadge(status: o.status)),
                              DataCell(Text(
                                o.paymentMethod,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _datePickerButton({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 6),
            Text(
              '$label: ',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade500),
            ),
            Text(
              isToday ? 'Hari Ini' : _dateFormat.format(date),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }

  Widget _quickDateBtn(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
        ),
      ),
    );
  }
}


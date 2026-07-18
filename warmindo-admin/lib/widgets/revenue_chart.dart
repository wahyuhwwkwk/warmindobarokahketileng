import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';

final _rpFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

class RevenueChart extends StatelessWidget {
  final List<OrderModel> orders;
  final bool isTodayOnly;

  const RevenueChart({super.key, required this.orders, this.isTodayOnly = false});

  @override
  Widget build(BuildContext context) {
    // When isTodayOnly is true → show 24-hour area chart
    if (isTodayOnly) {
      return _buildHourlyAreaChart(context);
    }

    // Multi-day → show bar chart as before
    return _buildDailyBarChart(context);
  }

  // ==========================================
  // 24-HOUR AREA CHART (Today filter)
  // ==========================================
  Widget _buildHourlyAreaChart(BuildContext context) {
    final hourlyData = _calculateHourlyRevenue();
    final totalRevenue = hourlyData.fold(0.0, (sum, e) => sum + e.revenue);
    final maxRevenue = hourlyData.map((e) => e.revenue).reduce((a, b) => a > b ? a : b);
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      padding: const EdgeInsets.all(20),
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
          _header(),
          const SizedBox(height: 8),
          Text(
            _rpFormat.format(totalRevenue),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFFF97316),
            ),
          ),
          Text(
            'Hari ini · ${hourlyData.where((e) => e.revenue > 0).length} jam aktif',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),
          // Area Chart
          SizedBox(
            height: isMobile ? 180 : 220,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 23,
                minY: 0,
                maxY: maxRevenue > 0 ? maxRevenue * 1.2 : 100,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipRoundedRadius: 10,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        final hour = spot.x.toInt();
                        return LineTooltipItem(
                          '${hour.toString().padLeft(2, '0')}:00\n${_rpFormat.format(spot.y)}',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: !isMobile,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        String label;
                        if (value >= 1000000) {
                          label = '${(value / 1000000).toStringAsFixed(1)}jt';
                        } else if (value >= 1000) {
                          label = '${(value / 1000).toStringAsFixed(0)}rb';
                        } else {
                          label = value.toStringAsFixed(0);
                        }
                        return Text(
                          label,
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: isMobile ? 4 : 2,
                      getTitlesWidget: (value, meta) {
                        final hour = value.toInt();
                        if (hour < 0 || hour > 23) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${hour.toString().padLeft(2, '0')}:00',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: maxRevenue > 0 ? maxRevenue / 4 : 25,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade100,
                    strokeWidth: 1,
                  ),
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: hourlyData.map((e) => FlSpot(e.hour.toDouble(), e.revenue)).toList(),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: const Color(0xFFF97316),
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        if (spot.y > 0) {
                          return FlDotCirclePainter(
                            radius: 3,
                            color: const Color(0xFFF97316),
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        }
                        return FlDotCirclePainter(radius: 0, color: Colors.transparent, strokeWidth: 0, strokeColor: Colors.transparent);
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFFF97316).withValues(alpha: 0.3),
                          const Color(0xFFF97316).withValues(alpha: 0.05),
                          const Color(0xFFF97316).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DAILY BAR CHART (Multi-day)
  // ==========================================
  Widget _buildDailyBarChart(BuildContext context) {
    final dailyRevenue = _calculateDailyRevenue();

    if (dailyRevenue.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
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
          children: [
            _header(),
            const SizedBox(height: 24),
            Icon(Icons.bar_chart_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text('Belum ada data pendapatan.', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          ],
        ),
      );
    }

    final maxRevenue = dailyRevenue.map((e) => e.revenue).reduce((a, b) => a > b ? a : b);
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      padding: const EdgeInsets.all(20),
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
          _header(),
          const SizedBox(height: 8),
          // Total summary
          Text(
            _rpFormat.format(dailyRevenue.fold(0.0, (sum, e) => sum + e.revenue)),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFFF97316),
            ),
          ),
          Text(
            '${dailyRevenue.length} hari · ${dailyRevenue.where((e) => e.revenue > 0).length} hari aktif',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),
          // Chart
          SizedBox(
            height: isMobile ? 180 : 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxRevenue * 1.15,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 10,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = dailyRevenue[group.x];
                      return BarTooltipItem(
                        '${item.label}\n${_rpFormat.format(item.revenue)}',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: !isMobile,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        String label;
                        if (value >= 1000000) {
                          label = '${(value / 1000000).toStringAsFixed(1)}jt';
                        } else if (value >= 1000) {
                          label = '${(value / 1000).toStringAsFixed(0)}rb';
                        } else {
                          label = value.toStringAsFixed(0);
                        }
                        return Text(
                          label,
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= dailyRevenue.length) {
                          return const SizedBox.shrink();
                        }
                        // Show every label if <= 7, else show every other
                        if (dailyRevenue.length > 7 && idx % 2 != 0) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            dailyRevenue[idx].shortLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: maxRevenue > 0 ? maxRevenue / 4 : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade100,
                    strokeWidth: 1,
                  ),
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(show: false),
                barGroups: dailyRevenue.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.revenue,
                        width: dailyRevenue.length <= 7 ? 28 : dailyRevenue.length <= 14 ? 16 : 10,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        gradient: entry.value.revenue > 0
                            ? const LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              )
                            : null,
                        color: entry.value.revenue == 0 ? Colors.grey.shade200 : null,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Icon(Icons.bar_chart_rounded, color: const Color(0xFFF97316), size: 20),
        const SizedBox(width: 8),
        const Text(
          'Grafik Pendapatan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // HOURLY REVENUE DATA (24h for today)
  // ==========================================
  List<_HourlyRevenueData> _calculateHourlyRevenue() {
    final validOrders = orders.where(
      (o) => o.status != 'CANCELLED' && o.status != 'WAITING_PAYMENT',
    ).toList();

    final result = <_HourlyRevenueData>[];
    for (int h = 0; h < 24; h++) {
      final hourRevenue = validOrders
          .where((o) {
            final local = o.createdAt.toLocal();
            return local.hour == h;
          })
          .fold(0.0, (sum, o) => sum + o.totalAmount);

      result.add(_HourlyRevenueData(hour: h, revenue: hourRevenue));
    }
    return result;
  }

  // ==========================================
  // DAILY REVENUE DATA (multi-day)
  // ==========================================
  List<_DailyRevenueData> _calculateDailyRevenue() {
    // Only count paid orders (not CANCELLED, not WAITING_PAYMENT)
    final validOrders = orders.where(
      (o) => o.status != 'CANCELLED' && o.status != 'WAITING_PAYMENT',
    ).toList();

    if (validOrders.isEmpty && orders.isEmpty) return [];

    // Find date range from orders — convert to local time first to avoid
    // UTC vs local timezone mismatch (createdAt from API may be in UTC)
    final allDates = orders.map((o) {
      final local = o.createdAt.toLocal();
      return DateTime(local.year, local.month, local.day);
    }).toSet().toList();
    if (allDates.isEmpty) return [];
    allDates.sort();

    final startDate = allDates.first;
    final endDate = allDates.last;
    final days = endDate.difference(startDate).inDays + 1;
    final dayCount = days > 30 ? 30 : days; // Max 30 days

    final dateFormat = DateFormat('dd MMM', 'id_ID');
    final shortFormat = DateFormat('dd/MM', 'id_ID');

    final result = <_DailyRevenueData>[];
    for (int i = 0; i < dayCount; i++) {
      final day = endDate.subtract(Duration(days: dayCount - 1 - i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59, 999);

      final dayRevenue = validOrders
          .where((o) {
            final local = o.createdAt.toLocal();
            return !local.isBefore(dayStart) && !local.isAfter(dayEnd);
          })
          .fold(0.0, (sum, o) => sum + o.totalAmount);

      result.add(_DailyRevenueData(
        date: day,
        revenue: dayRevenue,
        label: dateFormat.format(day),
        shortLabel: shortFormat.format(day),
      ));
    }

    return result;
  }
}

class _HourlyRevenueData {
  final int hour;
  final double revenue;

  _HourlyRevenueData({required this.hour, required this.revenue});
}

class _DailyRevenueData {
  final DateTime date;
  final double revenue;
  final String label;
  final String shortLabel;

  _DailyRevenueData({
    required this.date,
    required this.revenue,
    required this.label,
    required this.shortLabel,
  });
}

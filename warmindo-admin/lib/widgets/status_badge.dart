import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: _textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String get _label {
    switch (status) {
      case 'WAITING_PAYMENT': return 'MENUNGGU BAYAR';
      case 'PAID': return 'SUDAH BAYAR';
      case 'PROCESSING': return 'DIMASAK';
      case 'READY': return 'SIAP SAJI';
      case 'COMPLETED': return 'SELESAI';
      case 'CANCELLED': return 'BATAL';
      default: return status;
    }
  }

  Color get _bgColor {
    switch (status) {
      case 'WAITING_PAYMENT': return const Color(0xFFFEF3C7);
      case 'PAID': return const Color(0xFFDBEAFE);
      case 'PROCESSING': return const Color(0xFFF3E8FF);
      case 'READY': return const Color(0xFFDCFCE7);
      case 'COMPLETED': return const Color(0xFFF1F5F9);
      case 'CANCELLED': return const Color(0xFFFEE2E2);
      default: return Colors.grey.shade100;
    }
  }

  Color get _textColor {
    switch (status) {
      case 'WAITING_PAYMENT': return const Color(0xFFB45309);
      case 'PAID': return const Color(0xFF1D4ED8);
      case 'PROCESSING': return const Color(0xFF7C3AED);
      case 'READY': return const Color(0xFF15803D);
      case 'COMPLETED': return const Color(0xFF475569);
      case 'CANCELLED': return const Color(0xFFDC2626);
      default: return Colors.grey;
    }
  }

  Color get _borderColor {
    switch (status) {
      case 'WAITING_PAYMENT': return const Color(0xFFFDE68A);
      case 'PAID': return const Color(0xFFBFDBFE);
      case 'PROCESSING': return const Color(0xFFE9D5FF);
      case 'READY': return const Color(0xFFBBF7D0);
      case 'COMPLETED': return const Color(0xFFE2E8F0);
      case 'CANCELLED': return const Color(0xFFFECACA);
      default: return Colors.grey.shade300;
    }
  }
}

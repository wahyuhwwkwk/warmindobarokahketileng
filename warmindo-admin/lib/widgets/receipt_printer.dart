import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';

final _rpFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'id_ID');

class ReceiptPrinter {
  static void printReceipt(BuildContext context, OrderModel order) {
    Printing.layoutPdf(
      name: 'Struk_${order.orderNumber}',
      onLayout: (PdfPageFormat format) => _generateReceiptPdf(order),
    );
  }

  static Future<Uint8List> _generateReceiptPdf(OrderModel order) async {
    final pdf = pw.Document();
    final paymentLabel = order.paymentMethod == 'QRIS' ? 'QRIS' : 'TUNAI';
    final statusLabel = _getStatusLabel(order.status);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 5 * PdfPageFormat.mm),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Header
              pw.Text(
                'WARMINDO BAROKAH',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Sistem Pemesanan Digital',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 1.5),
              pw.SizedBox(height: 6),

              // Order info
              _infoRow('No. Order', order.orderNumber),
              _infoRow('Meja', order.tableNumberStr),
              if (order.customerName != null && order.customerName!.isNotEmpty)
                _infoRow('Nama', order.customerName!),
              _infoRow('Waktu', _dateTimeFormat.format(order.createdAt)),
              _infoRow('Status', statusLabel),
              pw.SizedBox(height: 6),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 6),

              // Items
              ...order.items.map((item) {
                final name = item.menu?.name ?? 'Menu';
                final qty = item.quantity;
                final subtotal = _rpFormat.format(item.price * qty);
                final details = <String>[];
                if (item.variantName != null && item.variantName!.isNotEmpty) details.add(item.variantName!);
                if (item.notes != null && item.notes!.isNotEmpty) details.add(item.notes!);

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text('${qty}x $name', style: const pw.TextStyle(fontSize: 11)),
                        ),
                        pw.Text(subtotal, style: const pw.TextStyle(fontSize: 11)),
                      ],
                    ),
                    if (details.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 16, bottom: 2),
                        child: pw.Text(
                          details.join(' - '),
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                        ),
                      ),
                    pw.SizedBox(height: 3),
                  ],
                );
              }),

              pw.SizedBox(height: 4),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 6),

              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    _rpFormat.format(order.totalAmount),
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              _infoRow('Pembayaran', paymentLabel),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 1.5),
              pw.SizedBox(height: 8),

              // Footer
              pw.Text(
                'Terima Kasih!',
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Selamat Menikmati',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Dicetak: ${_dateTimeFormat.format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey400),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static String _getStatusLabel(String status) {
    switch (status) {
      case 'WAITING_PAYMENT': return 'Menunggu Bayar';
      case 'PAID': return 'Sudah Bayar';
      case 'PROCESSING': return 'Dimasak';
      case 'READY': return 'Siap Saji';
      case 'COMPLETED': return 'Selesai';
      case 'CANCELLED': return 'Dibatalkan';
      default: return status;
    }
  }
}

import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/models/payment.dart';

class ReceiptGenerator {
  /// Generates a PDF receipt as raw bytes
  static Future<Uint8List> generateReceiptPdf({
    required Payment payment,
    double previousBalance = 0.0,
    double remainingBalance = 0.0,
    String? instituteName =
        'Indian Institute of Emergency & Critical Care Medicine',
    String? instituteSub =
        'Apex Academic Institute of Critical Care & Emergency Medicine',
    String? instituteContact =
        'admin@iiecm.org | +91 98765 43210 | www.iiecm.org',
  }) async {
    final pdf = pw.Document();

    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final formattedDate = dateFormat.format(payment.paymentDate);

    // IIECM Institutional Theme Colors for PDF
    final primaryForest = PdfColor.fromHex('#245B43');
    final darkForest = PdfColor.fromHex('#1A4331');
    final lightForest = PdfColor.fromHex('#E8F1EC');
    final warmCream = PdfColor.fromHex('#FAF7F0');
    final accentTerracotta = PdfColor.fromHex('#C87552');
    final textDark = PdfColor.fromHex('#292D29');
    final textSecondary = PdfColor.fromHex('#5F665E');
    final borderColor = PdfColor.fromHex('#E2DDD1');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: primaryForest, width: 2),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header Banner
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: lightForest,
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(8),
                    ),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 50,
                        height: 50,
                        decoration: pw.BoxDecoration(
                          color: primaryForest,
                          shape: pw.BoxShape.circle,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'IIECM',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 16),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              instituteName!,
                              style: pw.TextStyle(
                                color: darkForest,
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              instituteSub!,
                              style: pw.TextStyle(
                                color: textSecondary,
                                fontSize: 9,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              instituteContact!,
                              style: pw.TextStyle(
                                color: textSecondary,
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: pw.BoxDecoration(
                          color: payment.isVerified
                              ? primaryForest
                              : (payment.isPending
                                    ? accentTerracotta
                                    : PdfColors.grey),
                          borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(6),
                          ),
                        ),
                        child: pw.Text(
                          payment.status.toUpperCase(),
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 18),

                // Receipt Title & Meta Row
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'OFFICIAL FEE RECEIPT',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryForest,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Receipt No: ${payment.receiptNumber}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Date: $formattedDate',
                          style: pw.TextStyle(fontSize: 10, color: textDark),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Txn Ref: ${payment.transactionRef}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 14),
                pw.Divider(color: borderColor, thickness: 1),
                pw.SizedBox(height: 14),

                // Student and Academic Details Grid
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: warmCream,
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(8),
                    ),
                    border: pw.Border.all(color: borderColor),
                  ),
                  child: pw.Column(
                    children: [
                      _buildReceiptRow(
                        'Student Full Name',
                        payment.studentName,
                        'Student ID',
                        payment.studentCode ?? 'N/A',
                      ),
                      pw.SizedBox(height: 8),
                      _buildReceiptRow(
                        'Academic Course / Stream',
                        payment.courseName ??
                            (payment.subscriptionPlan != null
                                ? 'Subscription (${payment.subscriptionPlan})'
                                : 'Institutional Enrollment'),
                        'Payment Mode',
                        payment.formattedMethod,
                      ),
                      pw.SizedBox(height: 8),
                      _buildReceiptRow(
                        'Currency',
                        payment.currency,
                        'Authorized By',
                        payment.verifiedBy ?? 'System Verified',
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // Financial Breakdown Table
                pw.Table(
                  border: pw.TableBorder.all(color: borderColor, width: 1),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: lightForest),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Item Description',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                              color: darkForest,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Amount (INR)',
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                              color: darkForest,
                            ),
                          ),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Tuition & Clinical Training Fee installment for ${payment.courseName ?? "Institutional Program"}',
                            style: pw.TextStyle(fontSize: 10, color: textDark),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Rs. ${payment.amount.toStringAsFixed(2)}',
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 14),

                // Balances and Reconciliation Summary
                pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Container(
                    width: 240,
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: warmCream,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(6),
                      ),
                      border: pw.Border.all(color: borderColor),
                    ),
                    child: pw.Column(
                      children: [
                        if (previousBalance > 0) ...[
                          _buildMiniSummary(
                            'Previous Balance',
                            'Rs. ${previousBalance.toStringAsFixed(2)}',
                          ),
                          pw.SizedBox(height: 4),
                        ],
                        _buildMiniSummary(
                          'Amount Paid Now',
                          'Rs. ${payment.amount.toStringAsFixed(2)}',
                          isBold: true,
                          textColor: primaryForest,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Divider(color: borderColor, thickness: 0.5),
                        pw.SizedBox(height: 4),
                        _buildMiniSummary(
                          'Outstanding Balance',
                          'Rs. ${remainingBalance.toStringAsFixed(2)}',
                          isBold: true,
                          textColor: remainingBalance > 0
                              ? accentTerracotta
                              : primaryForest,
                        ),
                      ],
                    ),
                  ),
                ),

                if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                  pw.SizedBox(height: 14),
                  pw.Text(
                    'Administrative Remarks:',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 9,
                      color: textDark,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    payment.notes!,
                    style: pw.TextStyle(fontSize: 9, color: textSecondary),
                  ),
                ],

                pw.Spacer(),

                // Signatures & Official Validation Footer
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: primaryForest),
                            borderRadius: const pw.BorderRadius.all(
                              pw.Radius.circular(4),
                            ),
                          ),
                          child: pw.Text(
                            'ELECTRONICALLY AUDITED & VERIFIED',
                            style: pw.TextStyle(
                              fontSize: 8,
                              color: primaryForest,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'This is a computer-generated institutional receipt.',
                          style: pw.TextStyle(
                            fontSize: 7.5,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                          width: 120,
                          decoration: pw.BoxDecoration(
                            border: pw.Border(
                              bottom: pw.BorderSide(color: textDark, width: 1),
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Authorized Signatory',
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        pw.Text(
                          'Finance & Accounts Department, IIECM',
                          style: pw.TextStyle(
                            fontSize: 7,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildReceiptRow(
    String label1,
    String val1,
    String label2,
    String val2,
  ) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                label1.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 7.5,
                  color: PdfColor.fromHex('#5F665E'),
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 1),
              pw.Text(
                val1,
                style: pw.TextStyle(
                  fontSize: 9.5,
                  color: PdfColor.fromHex('#292D29'),
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                label2.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 7.5,
                  color: PdfColor.fromHex('#5F665E'),
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 1),
              pw.Text(
                val2,
                style: pw.TextStyle(
                  fontSize: 9.5,
                  color: PdfColor.fromHex('#292D29'),
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildMiniSummary(
    String label,
    String amount, {
    bool isBold = false,
    PdfColor? textColor,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            color: PdfColor.fromHex('#5F665E'),
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          amount,
          style: pw.TextStyle(
            fontSize: 9.5,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: textColor ?? PdfColor.fromHex('#292D29'),
          ),
        ),
      ],
    );
  }

  /// Plain text formatted receipt for clipboard copying and sharing
  static String formatReceiptPlainText({
    required Payment payment,
    double previousBalance = 0.0,
    double remainingBalance = 0.0,
  }) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final formattedDate = dateFormat.format(payment.paymentDate);

    return '''
============================================================
  INDIAN INSTITUTE OF EMERGENCY & CRITICAL CARE MEDICINE
============================================================
OFFICIAL PAYMENT RECEIPT
Receipt No     : ${payment.receiptNumber}
Date           : $formattedDate
Txn Reference  : ${payment.transactionRef}
------------------------------------------------------------
Student Name   : ${payment.studentName}
Student ID     : ${payment.studentCode ?? "N/A"}
Course/Stream  : ${payment.courseName ?? "Institutional Program"}
Payment Method : ${payment.formattedMethod}
Status         : ${payment.status.toUpperCase()}
------------------------------------------------------------
Amount Paid    : Rs. ${payment.amount.toStringAsFixed(2)}
Previous Bal   : Rs. ${previousBalance.toStringAsFixed(2)}
Remaining Bal  : Rs. ${remainingBalance.toStringAsFixed(2)}
------------------------------------------------------------
Authorized By  : ${payment.verifiedBy ?? "Institutional Admin"}
Verified Status: ELECTRONICALLY AUDITED & VERIFIED
============================================================''';
  }
}

//import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_html/html.dart' as html; // Fixed import statement

class PdfGenerator {
  static Future<void> generateAndDownloadPDF({
    required String className,
    required List<Map<String, dynamic>> filteredStudents,
    required double totalFees,
    required double totalCollected,
    required double remainingAmount,
    required double scholarshipAmount,
    required String feePeriod,
    required String paymentstatus,
    required BuildContext context,
  }) async {
    // Load the font file
    final fontData = await rootBundle.load("assets/fonts/NotoSans-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);

    final pdf = pw.Document();

    // Define styles with the loaded font
    final headerStyle = pw.TextStyle(
      font: ttf,
      fontSize: 20,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blue900,
    );
    final subHeaderStyle = pw.TextStyle(
      font: ttf,
      fontSize: 14,
      color: PdfColors.grey700,
    );
    final tableHeaderStyle = pw.TextStyle(
      font: ttf,
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
    );
    final tableContentStyle = pw.TextStyle(
      font: ttf,
      fontSize: 10,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Class $className Report', style: headerStyle),
                pw.Text(
                  'Generated: ${DateTime.now().toString().split('.')[0]}',
                  style: subHeaderStyle,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Summary', style: headerStyle),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Total Students: ${filteredStudents.length}',
                            style: tableContentStyle),
                        pw.Text(
                            'Fee Structure: Rs.${totalFees.toStringAsFixed(2)}',
                            style: tableContentStyle),
                        pw.Text('Fee Period: $feePeriod',
                            style: tableContentStyle),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                            'Total Fees to be Collected: Rs.${(totalFees * filteredStudents.length).toStringAsFixed(2)}',
                            style: tableContentStyle),
                        pw.Text(
                            'Total Collected: Rs.${totalCollected.toStringAsFixed(2)}',
                            style: tableContentStyle),
                        pw.Text(
                            'Remaining: Rs.${remainingAmount.toStringAsFixed(2)}',
                            style: tableContentStyle),
                        pw.Text(
                            'Scholarship: Rs.${scholarshipAmount.toStringAsFixed(2)}',
                            style: tableContentStyle),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: [
              'Name',
              'EMIS Number',
              'Status',
              'Amount Paid',
              'Arrear',
              'Remaining'
            ],
            headerStyle: tableHeaderStyle,
            headerDecoration: pw.BoxDecoration(color: PdfColors.grey200),
            cellStyle: tableContentStyle,
            cellHeight: 30,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
            },
            data: filteredStudents.map((student) {
              final amountPaid =
                  double.tryParse(student['AmountPaid']?.toString() ?? '0') ??
                      0.0;
              final remaining = double.tryParse(
                      student['RemainingAmount']?.toString() ?? '0') ??
                  0.0;
              final arrear =
                  double.tryParse(student['Arrearamount']?.toString() ?? '0') ??
                      0.0;

              return [
                student['StudentName'] ?? 'N/A',
                student['EMISNo'] ?? 'N/A',
                _getPaymentStatus(amountPaid, totalFees),
                'Rs.${amountPaid.toStringAsFixed(2)}',
                'Rs.${arrear.toStringAsFixed(2)}',
                'Rs.${remaining.toStringAsFixed(2)}'
              ];
            }).toList(),
          ),
        ],
      ),
    );
    final bytes = await pdf.save();

    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement()
        ..href = url
        ..style.display = 'none'
        ..download = 'Class_$className $paymentstatus Report.pdf';
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    }
  }

  static String _getPaymentStatus(double amountPaid, double totalFees) {
    if (amountPaid >= totalFees) return 'Paid';
    if (amountPaid > 0) return 'Partially Paid';
    return 'Unpaid';
  }
}

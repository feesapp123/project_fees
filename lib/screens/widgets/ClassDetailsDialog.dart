import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:data_table_2/data_table_2.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

class ClassDetailsDialog extends StatefulWidget {
  final String className;
  final List<Map<String, dynamic>> studentsInClass;
  final String searchQuery;
  final void Function(Map<String, dynamic>) onStudentTapped;

  const ClassDetailsDialog({
    super.key,
    required this.className,
    required this.studentsInClass,
    required this.searchQuery,
    required this.onStudentTapped,
  });

  @override
  _ClassDetailsDialogState createState() => _ClassDetailsDialogState();
}

class _ClassDetailsDialogState extends State<ClassDetailsDialog> {
  List<Map<String, dynamic>> classFees = [];
  List<Map<String, dynamic>> filteredStudents = [];
  double totalFees = 0.0;
  double scholarshipAmount = 0.0;
  String feePeriod = '';
  String selectedStatus = 'All';
  bool isLoading = false;

  final List<String> statusFilters = [
    'All',
    'Paid',
    'Partially Paid',
    'Unpaid'
  ];

  @override
  void initState() {
    super.initState();
    fetchClassDetails(widget.searchQuery);
  }

  Future<void> fetchClassDetails(String searchQuery) async {
    setState(() => isLoading = true);
    try {
      // Fetch class fee details
      final feeResponse = await http.get(Uri.parse(
          "http://localhost/fees/fetch_fees.php?className=${widget.className}"));

      if (feeResponse.statusCode == 200) {
        final feeData = json.decode(feeResponse.body);
        setState(() {
          classFees = List<Map<String, dynamic>>.from(feeData);
          if (classFees.isNotEmpty) {
            totalFees =
                double.tryParse(classFees[0]['TotalFee'].toString()) ?? 0.0;
            scholarshipAmount =
                double.tryParse(classFees[0]['ScholarshipAmount'].toString()) ??
                    0.0;
            feePeriod = classFees[0]['FeePeriod'] ?? '';
          }
        });
      }

      // Fetch students with search query and status filter
      final studentResponse = await http.get(Uri.parse(
          "http://localhost/fees/filter_status.php?className=${widget.className}&search=$searchQuery&status=${selectedStatus != 'All' ? selectedStatus : ''}"));

      if (studentResponse.statusCode == 200) {
        final data = json.decode(studentResponse.body);
        if (data != null && data['data'] != null) {
          setState(() {
            filteredStudents = List<Map<String, dynamic>>.from(data['data']);
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching class details: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> generateAndDownloadPDF() async {
    final pdf = pw.Document();

    // Add title and class information
    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Class: ${widget.className}',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Total Fees: ₹${totalFees.toStringAsFixed(2)}'),
              pw.Text(
                  'Scholarship Amount: ₹${scholarshipAmount.toStringAsFixed(2)}'),
              pw.Text('Fee Period: $feePeriod'),
              pw.SizedBox(height: 20),
              // Create table
              // ignore: deprecated_member_use
              pw.Table.fromTextArray(
                headers: [
                  'Name',
                  'Emis Number',
                  'Status',
                  'Amount Paid',
                  'Remaining'
                ],
                data: filteredStudents.map((student) {
                  final amountPaid = double.tryParse(
                          student['AmountPaid']?.toString() ?? '0') ??
                      0.0;
                  final remaining = totalFees - amountPaid;
                  return [
                    student['StudentName'] ?? 'N/A',
                    student['EMISNo'] ?? 'N/A',
                    student['PaymentStatus'] ?? 'N/A',
                    '₹${amountPaid.toStringAsFixed(2)}',
                    '₹${remaining.toStringAsFixed(2)}'
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    // Save the PDF
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/Class_${widget.className}_Report.pdf');
    await file.writeAsBytes(await pdf.save());

    // Open the PDF
    await OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Class: ${widget.className}',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.download),
                      label: Text('Export PDF'),
                      onPressed: generateAndDownloadPDF,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: Icon(Icons.close),
                      label: Text('Close'),
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Fees',
                              style: TextStyle(color: Colors.grey)),
                          Text(
                            '₹${totalFees.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Scholarship',
                              style: TextStyle(color: Colors.grey)),
                          Text(
                            '₹${scholarshipAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Students',
                              style: TextStyle(color: Colors.grey)),
                          Text(
                            '${filteredStudents.length}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Filter by Status',
                      border: OutlineInputBorder(),
                    ),
                    items: statusFilters.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedStatus = value!);
                      fetchClassDetails(widget.searchQuery);
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : DataTable2(
                      columns: [
                        DataColumn2(label: Text('Name'), size: ColumnSize.L),
                        DataColumn2(
                            label: Text('Emis Number'), size: ColumnSize.L),
                        DataColumn2(label: Text('Status'), size: ColumnSize.M),
                        DataColumn2(
                            label: Text('Amount Paid'), size: ColumnSize.M),
                        DataColumn2(
                            label: Text('Remaining'), size: ColumnSize.M),
                      ],
                      rows: filteredStudents.map((student) {
                        final amountPaid = double.tryParse(
                                student['AmountPaid']?.toString() ?? '0') ??
                            0.0;
                        final remaining = totalFees - amountPaid;
                        return DataRow(
                          cells: [
                            DataCell(Text(student['StudentName'] ?? 'N/A')),
                            DataCell(Text(student['EMISNo'] ?? 'N/A')),
                            DataCell(
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                      student['PaymentStatus'] ?? 'N/A'),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(student['PaymentStatus'] ?? 'N/A'),
                              ),
                            ),
                            DataCell(Text('₹${amountPaid.toStringAsFixed(2)}')),
                            DataCell(
                              Text(
                                '₹${remaining.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color:
                                      remaining > 0 ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          onSelectChanged: (selected) {
                            if (selected == true) {
                              widget.onStudentTapped(student);
                            }
                          },
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green[100]!;
      case 'partially paid':
        return Colors.orange[100]!;
      case 'unpaid':
        return Colors.red[100]!;
      default:
        return Colors.grey[100]!;
    }
  }
}

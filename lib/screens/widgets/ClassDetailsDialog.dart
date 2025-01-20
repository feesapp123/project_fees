import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:data_table_2/data_table_2.dart';
import 'package:project_fees/screens/StudentProfileScreen.dart';
import 'package:project_fees/screens/pdf_generation.dart';

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
  double totalCollected = 0.0;
  double remainingAmount = 0.0;
  double remaining = 0.0;
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

  void applyStatusFilter() async {
    setState(() => isLoading = true);

    try {
      final studentResponse = await http.get(Uri.parse(
          "http://localhost/fees/filter_status.php?className=${widget.className}&status=${selectedStatus != 'All' ? selectedStatus : ''}"));

      if (studentResponse.statusCode == 200) {
        final data = json.decode(studentResponse.body);
        if (data != null && data['data'] != null) {
          setState(() {
            filteredStudents = List<Map<String, dynamic>>.from(data['data']);
          });
        }
      }
    } catch (e) {
      debugPrint('Error applying status filter: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void calculateTotalCollectedAndRemaining() {
    double totalAmountToBeCollected = 0.0;
    double totalAmountPaid = 0.0;

    // Calculate totals for all students in the class (not filtered)
    for (var student in widget.studentsInClass) {
      totalAmountToBeCollected += totalFees; // Total fees per student
      totalAmountPaid +=
          double.tryParse(student['AmountPaid']?.toString() ?? '0') ?? 0.0;
    }

    // Update the totals
    totalCollected = totalAmountPaid;
    remainingAmount =
        totalAmountToBeCollected - totalCollected - scholarshipAmount;
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
          "http://localhost/fees/fetch_students.php?className=${widget.className}"));

      if (studentResponse.statusCode == 200) {
        final data = json.decode(studentResponse.body);
        if (data != null && data['data'] != null) {
          setState(() {
            filteredStudents = List<Map<String, dynamic>>.from(data['data']);
          });
          calculateTotalCollectedAndRemaining();
        }
      }
    } catch (e) {
      debugPrint('Error fetching class details: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

// In your ClassDetailsDialog

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
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
                          Text('Fee structure : ₹$totalFees',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      const Color.fromARGB(255, 85, 227, 61))),
                          Text('Fee Period: $feePeriod',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue)),
                          SizedBox(height: 8),
                          Text('Total Students: ${filteredStudents.length}',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      const Color.fromARGB(255, 239, 190, 67))),
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
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Fees to be Collected',
                              style: TextStyle(color: Colors.grey)),
                          Text(
                            '₹${(totalFees * filteredStudents.length).toStringAsFixed(2)}',
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
                          Text('Total Fees Collected',
                              style: TextStyle(color: Colors.grey)),
                          Text(
                            '₹${totalCollected.toStringAsFixed(2)}',
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
                          Text('Remaining Amount',
                              style: TextStyle(color: Colors.grey)),
                          Text(
                            '₹${remainingAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
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
                      applyStatusFilter(); // Apply filter after selection
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
                            label: Text('Arrear Amount'), size: ColumnSize.M),
                        DataColumn2(
                            label: Text('Remaining'), size: ColumnSize.M),
                      ],
                      rows: filteredStudents.map((student) {
                        final amountPaid = double.tryParse(
                                student['AmountPaid']?.toString() ?? '0') ??
                            0.0;
                        final remaining = double.tryParse(
                                student['RemainingAmount']?.toString() ??
                                    '0') ??
                            0.0;
                        final arrear = double.tryParse(
                                student['Arrearamount']?.toString() ?? '0') ??
                            0.0;
                        //debugPrint('Arrear amount:$arrear');
                        String paymentStatus;
                        if (amountPaid >= totalFees) {
                          paymentStatus = 'Paid';
                        } else if (amountPaid > 0) {
                          paymentStatus = 'Partially Paid';
                        } else {
                          paymentStatus = 'Unpaid';
                        }
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(student['StudentName'] ?? 'N/A'),
                              onTap: () => _navigateToStudentProfile(student),
                            ),
                            DataCell(
                              Text(student['EMISNo'] ?? 'N/A'),
                              onTap: () => _navigateToStudentProfile(student),
                            ),
                            DataCell(
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(paymentStatus),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(paymentStatus),
                              ),
                              onTap: () => _navigateToStudentProfile(student),
                            ),
                            DataCell(
                              Text('₹${amountPaid.toStringAsFixed(2)}'),
                              onTap: () => _navigateToStudentProfile(student),
                            ),
                            DataCell(
                              Text('₹${arrear.toStringAsFixed(2)}'),
                              onTap: () => _navigateToStudentProfile(student),
                            ),
                            DataCell(
                              Text('₹${remaining.toStringAsFixed(2)}'),
                              onTap: () => _navigateToStudentProfile(student),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void generateAndDownloadPDF() async {
    // Filter students based on payment status
    List<Map<String, dynamic>> filteredByStatus;
    final String paymentstatus = selectedStatus;
    switch (paymentstatus) {
      case 'Paid':
        filteredByStatus = filteredStudents.where((student) {
          double amountPaid =
              double.tryParse(student['AmountPaid']?.toString() ?? '0') ?? 0.0;
          return amountPaid >= totalFees;
        }).toList();
        break;

      case 'Partially Paid':
        filteredByStatus = filteredStudents.where((student) {
          double amountPaid =
              double.tryParse(student['AmountPaid']?.toString() ?? '0') ?? 0.0;
          return amountPaid > 0 && amountPaid < totalFees;
        }).toList();
        break;

      case 'Unpaid':
        filteredByStatus = filteredStudents.where((student) {
          double amountPaid =
              double.tryParse(student['AmountPaid']?.toString() ?? '0') ?? 0.0;
          return amountPaid == 0;
        }).toList();
        break;

      default:
        filteredByStatus = filteredStudents;
    }

    // Pass the filtered students to the PDF generation
    await PdfGenerator.generateAndDownloadPDF(
      className: widget.className,
      filteredStudents: filteredByStatus,
      totalFees: totalFees,
      totalCollected: totalCollected,
      remainingAmount: remainingAmount,
      scholarshipAmount: scholarshipAmount,
      feePeriod: feePeriod,
      paymentstatus: paymentstatus,
      context: context,
    );
  }

  void _navigateToStudentProfile(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => StudentProfileScreen(student: student),
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

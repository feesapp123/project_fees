import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MarkPaymentScreen extends StatefulWidget {
  const MarkPaymentScreen({super.key});

  @override
  _MarkPaymentScreenState createState() => _MarkPaymentScreenState();
}

class _MarkPaymentScreenState extends State<MarkPaymentScreen> {
  String? selectedClass;
  String? selectedStudent;
  List<String> classes = [];
  List<Map<String, dynamic>> students = [];
  double totalFee = 0.0;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchClasses();
  }

  Future<void> fetchClasses() async {
    setState(() => isLoading = true);
    try {
      final response = await http
          .get(
            Uri.parse("http://localhost/fees/fetch_classes.php"),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          classes = List<String>.from(responseData);
        });
      } else {
        _showErrorSnackBar('Failed to load classes. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('Network error. Please check your connection.');
      debugPrint('Error in fetchClasses: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchStudents(String className) async {
    setState(() => isLoading = true);
    try {
      final response = await http
          .get(
            Uri.parse(
                "http://localhost/fees/fetch_students.php?className=$className"),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('Fetching data for class: $className');
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success' && data['data'] != null) {
          setState(() {
            students =
                List<Map<String, dynamic>>.from(data['data']).map((student) {
              return {
                ...student,
                'LastPaymentDate': student['LastPaymentDate'] == "0000-00-00"
                    ? null
                    : student['LastPaymentDate'],
                'AmountPaid':
                    double.tryParse(student['AmountPaid']?.toString() ?? '0') ??
                        0.0,
              };
            }).toList();
          });
        } else {
          _showErrorSnackBar(data['message'] ?? 'Failed to fetch students');
          setState(() => students = []);
        }
      } else {
        _showErrorSnackBar('Server error. Please try again later.');
        setState(() => students = []);
      }
    } catch (e) {
      _showErrorSnackBar('Network error. Please check your connection.');
      debugPrint('Error in fetchStudents: $e');
      setState(() => students = []);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchTotalFee(String className) async {
    try {
      final response = await http.post(
        Uri.parse("http://localhost/fees/fetch_fees.php"),
        body: {'className': className},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          if (data is Map<String, dynamic>) {
            setState(() {
              totalFee = double.tryParse(data['TotalFee'].toString()) ?? 0.0;
            });
          } else if (data is List && data.isNotEmpty) {
            final feeData = data[0];
            setState(() {
              totalFee = double.tryParse(feeData['TotalFee'].toString()) ?? 0.0;
            });
          } else {
            _showErrorSnackBar('Invalid fee data format received');
            setState(() => totalFee = 0.0);
          }
        } catch (e) {
          _showErrorSnackBar('Error processing fee data');
          debugPrint('Error parsing fee data: $e');
          setState(() => totalFee = 0.0);
        }
      } else {
        _showErrorSnackBar('Failed to load fee information');
        setState(() => totalFee = 0.0);
      }
    } catch (e) {
      _showErrorSnackBar('Network error. Please check your connection.');
      debugPrint('Error in fetchTotalFee: $e');
      setState(() => totalFee = 0.0);
    }
  }

  Future<void> _savePayment(String studentName, double amountPaid,
      String status, String paymentDate) async {
    try {
      final response = await http
          .post(
            Uri.parse("http://localhost/fees/save_payment.php"),
            headers: {"Content-Type": "application/json"},
            body: json.encode({
              'studentName': studentName,
              'class': selectedClass,
              'amountPaid': amountPaid,
              'status': status,
              'paymentDate': paymentDate,
            }),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('Save payment response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _showSuccessSnackBar('Payment saved successfully!');
          // Refresh student data
          if (selectedClass != null) {
            fetchStudents(selectedClass!);
          }
        } else {
          _showErrorSnackBar(data['error'] ?? 'Failed to save payment');
        }
      } else {
        _showErrorSnackBar('Server error. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('Network error. Please check your connection.');
      debugPrint('Error in _savePayment: $e');
    }
  }

  void _showPaymentDialog(BuildContext context, Map<String, dynamic> student) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController dateController =
        TextEditingController(text: DateTime.now().toString().split(' ')[0]);

    double studentAmountPaid = student['AmountPaid'] ?? 0.0;
    double remainingAmount = totalFee - studentAmountPaid;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark Payment for ${student['StudentName']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Class: $selectedClass'),
              Text('Total Fee: ₹${totalFee.toStringAsFixed(2)}'),
              if (student['LastPaymentDate'] != null)
                Text('Last Payment: ${student['LastPaymentDate']}'),
              Text('Amount Paid: ₹${studentAmountPaid.toStringAsFixed(2)}'),
              Text(
                'Remaining: ₹${remainingAmount.toStringAsFixed(2)}',
                style: TextStyle(
                    color: remainingAmount > 0 ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Enter Amount Paid',
                  border: OutlineInputBorder(),
                  hintText: 'Remaining: ₹${remainingAmount.toStringAsFixed(2)}',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: dateController,
                decoration: const InputDecoration(
                  labelText: 'Payment Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    dateController.text = picked.toString().split(' ')[0];
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final double? newPayment = double.tryParse(amountController.text);
              if (newPayment == null || newPayment <= 0) {
                _showErrorSnackBar('Please enter a valid amount');
                return;
              }

              double totalPaid = studentAmountPaid + newPayment;
              String newStatus;
              if (totalPaid >= totalFee) {
                newStatus = 'Paid';
              } else if (totalPaid > 0) {
                newStatus = 'Partially Paid';
              } else {
                newStatus = 'Unpaid';
              }

              _savePayment(
                student['StudentName'],
                newPayment,
                newStatus,
                dateController.text,
              );

              Navigator.pop(context);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Payment'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: selectedClass,
                  hint: const Text('Select Class'),
                  items: classes.map((className) {
                    return DropdownMenuItem<String>(
                      value: className,
                      child: Text(className),
                    );
                  }).toList(),
                  onChanged: (className) {
                    setState(() {
                      selectedClass = className;
                      students = [];
                    });
                    if (className != null) {
                      fetchStudents(className);
                      fetchTotalFee(className);
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Class',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: students.isEmpty
                      ? Center(
                          child: Text(
                            selectedClass == null
                                ? 'Please select a class'
                                : 'No students found',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                      : ListView.builder(
                          itemCount: students.length,
                          itemBuilder: (context, index) {
                            final student = students[index];
                            final studentName =
                                student['StudentName'] ?? 'Unknown';
                            final fathersName =
                                student['FathersName'] ?? 'Not Available';
                            final paymentStatus =
                                student['PaymentStatus'] ?? 'N/A';
                            final amountPaid = student['AmountPaid'] ?? 0.0;
                            final remaining = totalFee - amountPaid;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                title: Text(
                                  studentName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Father: $fathersName'),
                                    Text(
                                      'Remaining: ₹${remaining.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: remaining > 0
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Chip(
                                  label: Text(paymentStatus),
                                  backgroundColor:
                                      _getStatusColor(paymentStatus),
                                ),
                                onTap: () =>
                                    _showPaymentDialog(context, student),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
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

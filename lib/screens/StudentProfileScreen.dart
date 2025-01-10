import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StudentProfileScreen extends StatefulWidget {
  final Map<String, dynamic> student;

  const StudentProfileScreen({super.key, required this.student});

  @override
  _StudentProfileScreenState createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  double totalFee = 0.0;

  @override
  void initState() {
    super.initState();
    fetchTotalFee();
  }

  Future<void> fetchTotalFee() async {
    try {
      final response = await http.get(
        Uri.parse(
          "http://localhost/fees/fetch_fees.php?className=${widget.student['Class']}",
        ),
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body)[0];

        // Check if 'TotalFee' is an integer or string and parse it accordingly
        setState(() {
          if (responseData['TotalFee'] is int) {
            totalFee = (responseData['TotalFee'] as int).toDouble();
          } else if (responseData['TotalFee'] is String) {
            totalFee = double.tryParse(responseData['TotalFee']) ?? 0.0;
          } else {
            totalFee = 0.0;
          }
        });
      } else {
        debugPrint('Failed to fetch total fee: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching total fee: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;

    // Safely access the fields to prevent null errors
    final studentName = student['StudentName'] ?? 'Not Available';
    final className = student['Class'] ?? 'Not Available';
    final fathersName = student['FathersName'] ?? 'Not Available';
    final phoneNumber = student['PhoneNumber'] ?? 'Not Available';
    final dob = student['DOB'] ?? 'Not Available';
    final caste = student['Caste'] ?? 'Not Available';
    final emisNo = student['EMISNo'] ?? 'Not Available';
    final feesPaid =
        double.tryParse(student['AmountPaid']?.toString() ?? '0') ?? 0.0;

    final remainingAmount = totalFee - feesPaid;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Student Details
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Picture or Icon
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blueAccent,
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Student Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildDetailRow('Name:', studentName),
                    _buildDetailRow('Class:', className),
                    _buildDetailRow('Father\'s Name:', fathersName),
                    _buildDetailRow('Phone:', phoneNumber),
                    _buildDetailRow('DOB:', dob),
                    _buildDetailRow('Caste:', caste),
                    _buildDetailRow('EMIS No:', emisNo),
                  ],
                ),
              ),
              SizedBox(width: 16),
              // Right: Fee Details
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fee Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildDetailRow(
                        'Fees Paid:', '₹${feesPaid.toStringAsFixed(2)}'),
                    _buildDetailRow(
                      'Payment Status:',
                      student['PaymentStatus'] == 'Paid' ? 'Paid' : 'Pending',
                      valueColor: student['PaymentStatus'] == 'Paid'
                          ? Colors.green
                          : Colors.red,
                    ),
                    if (student['PaymentStatus'] != 'Paid')
                      _buildDetailRow(
                        'Remaining Amount:',
                        '₹${remainingAmount > 0 ? remainingAmount.toStringAsFixed(2) : "0.00"}',
                        valueColor: Colors.red,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build detail rows with optional color
  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor ?? Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

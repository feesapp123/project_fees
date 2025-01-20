import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PaymentHistoryDialog extends StatelessWidget {
  final int studentID;

  PaymentHistoryDialog({required this.studentID});

  Future<List<Map<String, dynamic>>> fetchPaymentHistory() async {
    try {
      final response = await http.get(
        Uri.parse(
            "http://localhost/fees/get_payment_history.php?studentID=$studentID"),
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load payment history');
      }
    } catch (e) {
      throw Exception('Error fetching payment history: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Payment History'),
      content: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchPaymentHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Text('No payment history found.');
          } else {
            final paymentHistory = snapshot.data!;
            return SingleChildScrollView(
              child: Column(
                children: paymentHistory.map((payment) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: Icon(
                        Icons.payment,
                        color: payment['PaymentStatus'] == 'Paid'
                            ? Colors.green
                            : Colors.red,
                      ),
                      title: Text('Amount Paid: ₹${payment['AmountPaid']}'),
                      subtitle: Text('Status: ${payment['PaymentStatus']}'),
                      trailing: Text('Date: ${payment['PaymentDate']}'),
                    ),
                  );
                }).toList(),
              ),
            );
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context); // Close the dialog
          },
          child: const Text('Close'),
        ),
        TextButton(
          onPressed: () {
            // Trigger a refresh
            (context as Element).reassemble();
          },
          child: const Text('Refresh'),
        ),
      ],
    );
  }
}

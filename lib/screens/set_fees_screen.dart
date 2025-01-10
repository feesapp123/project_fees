import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SetFeesScreen extends StatefulWidget {
  const SetFeesScreen({super.key});

  @override
  _SetFeesScreenState createState() => _SetFeesScreenState();
}

class _SetFeesScreenState extends State<SetFeesScreen> {
  final TextEditingController _totalFeeController = TextEditingController();
  final TextEditingController _scholarshipAmountController =
      TextEditingController();
  final TextEditingController _feePeriodController = TextEditingController();

  List<String> availableClasses = []; // List of classes
  String? selectedClass; // Currently selected class
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchClasses(); // Fetch available classes on initialization
  }

  /// Fetches the list of available classes
  Future<void> fetchClasses() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response =
          await http.get(Uri.parse('http://localhost/fees/fetch_classes.php'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.isNotEmpty) {
          setState(() {
            availableClasses = List<String>.from(data);
          });
        } else {
          showError('No classes available');
        }
      } else {
        showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      showError('Error fetching classes: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Fetches fee details for a specific class
  Future<void> fetchFeeDetails(String className) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Debugging: Print class name and request being sent
      debugPrint('Sending request for class: $className');
      final response = await http.post(
        Uri.parse('http://localhost/fees/fetch_fees.php'),
        body: {'className': className},
      );

      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}'); // Print the raw response

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Decoded data: $data'); // Log the decoded response

        if (data is List && data.isNotEmpty) {
          final feeDetails = data[0]; // Get the first item
          setState(() {
            _totalFeeController.text = feeDetails['TotalFee']?.toString() ?? '';
            _scholarshipAmountController.text =
                feeDetails['ScholarshipAmount']?.toString() ?? '';
            _feePeriodController.text =
                feeDetails['FeePeriod']?.toString() ?? '';
          });
        } else if (data is Map && data['status'] == 'error') {
          showError(data['message']);
          clearFeeFields();
        } else {
          showError('No fee data found for selected class');
          clearFeeFields();
        }
      } else {
        showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      showError('Error fetching fee details: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Clears input fields
  void clearFeeFields() {
    _totalFeeController.clear();
    _scholarshipAmountController.clear();
    _feePeriodController.clear();
  }

  /// Updates fee details for the selected class
  Future<void> updateFees() async {
    if (selectedClass == null) {
      showError('Please select a class');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost/fees/update_fees.php'),
        body: {
          'class': selectedClass!,
          'total_fee': _totalFeeController.text,
          'scholarship_amount': _scholarshipAmountController.text,
          'fee_period': _feePeriodController.text,
        },
      );

      final responseData = json.decode(response.body);

      if (responseData['status'] == 'success') {
        showSuccess('Fee details updated successfully');
      } else {
        showError(responseData['message'] ?? 'Failed to update fee details');
      }
    } catch (e) {
      showError('Error updating fees: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Displays an error message
  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.red)),
    ));
  }

  /// Displays a success message
  void showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.green)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Set Fees"),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedClass,
                    decoration: InputDecoration(
                      labelText: "Select Class",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: availableClasses.map((className) {
                      return DropdownMenuItem<String>(
                        value: className,
                        child: Text(className),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedClass = value;
                      });
                      if (value != null) {
                        fetchFeeDetails(value);
                      }
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _totalFeeController,
                    decoration: const InputDecoration(
                      labelText: 'Total Fee',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _scholarshipAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Scholarship Amount',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _feePeriodController,
                    decoration: const InputDecoration(
                      labelText: 'Fee Period',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 20.0),
                  ElevatedButton(
                    onPressed: updateFees,
                    child: const Text("Update Fees"),
                  ),
                ],
              ),
            ),
    );
  }
}

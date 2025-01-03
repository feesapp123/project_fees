import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditStudentDetailsScreen extends StatefulWidget {
  const EditStudentDetailsScreen({super.key});

  @override
  _EditStudentDetailsScreenState createState() =>
      _EditStudentDetailsScreenState();
}

class _EditStudentDetailsScreenState extends State<EditStudentDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emisController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _casteController = TextEditingController();

  bool _isSubmitting = false;
  String _statusMessage = "";

  // Function to format date in DD/MM/YYYY format
  String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Function to select the date from DatePicker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      final formattedDate = formatDate(selectedDate);
      _dobController.text = formattedDate; // Set the text to the formatted date
    }
  }

  // Function to handle form submission
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _statusMessage = "";
    });

    // Prepare the data to be sent to the PHP backend
    final Map<String, String> formData = {
      'emis': _emisController.text,
      'name': _nameController.text,
      'class': _classController.text,
      'father_name': _fatherNameController.text,
      'phone': _phoneController.text,
      'dob': _dobController.text,
      'caste': _casteController.text,
    };

    // Make the HTTP POST request to the PHP backend
    try {
      final response = await http.post(
        Uri.parse(
            'http://localhost/fees/update_student.php'), // Replace with your server URL
        body: formData,
      );
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          _statusMessage = responseData['message'];
        });
      } else {
        setState(() {
          _statusMessage = "Failed to update student details.";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Error: $e";
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Student Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _emisController,
                    decoration: const InputDecoration(labelText: 'EMIS No'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter EMIS No';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _classController,
                    decoration: const InputDecoration(labelText: 'Class'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter class';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _fatherNameController,
                    decoration:
                        const InputDecoration(labelText: 'Father\'s Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter father\'s name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _phoneController,
                    decoration:
                        const InputDecoration(labelText: 'Phone Number'),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter phone number';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _dobController,
                    decoration:
                        const InputDecoration(labelText: 'Date of Birth'),
                    keyboardType: TextInputType.datetime,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter date of birth';
                      }

                      // Optionally, validate the format (DD/MM/YYYY)
                      RegExp regExp = RegExp(r'^\d{2}/\d{2}/\d{4}$');
                      if (!regExp.hasMatch(value)) {
                        return 'Please enter a valid date in DD/MM/YYYY format';
                      }

                      return null;
                    },
                    onTap: () {
                      FocusScope.of(context)
                          .requestFocus(FocusNode()); // Remove keyboard on tap
                      _selectDate(context); // Show date picker on tap
                    },
                  ),
                  TextFormField(
                    controller: _casteController,
                    decoration: const InputDecoration(labelText: 'Caste'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter caste';
                      }
                      return null;
                    },
                  ),
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: _isSubmitting
                        ? const CircularProgressIndicator()
                        : const Text('Submit'),
                  ),
                ],
              ),
            ),
            if (_statusMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                      color: _statusMessage.contains("exists")
                          ? Colors.red
                          : Colors.green),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

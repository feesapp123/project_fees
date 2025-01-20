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

  // Function to check if student exists and load the details
  // Function to check if student exists and load the details
  Future<void> _loadStudentDetails() async {
    final emisNo = _emisController.text;

    if (emisNo.isEmpty) {
      setState(() {
        _statusMessage = "Please enter the EMIS number.";
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _statusMessage = "";
    });

    // Make the HTTP POST request to the PHP backend to check student
    try {
      final response = await http.post(
        Uri.parse(
            'http://localhost/fees/check_student.php'), // Replace with your PHP URL
        body: {'emis': emisNo},
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        // If student exists, populate the fields with existing data
        final studentDetails = responseData['studentDetails'];
        _nameController.text = studentDetails['StudentName'];
        _classController.text = studentDetails['Class'];
        _fatherNameController.text = studentDetails['FathersName'];
        _phoneController.text = studentDetails['PhoneNumber'];
        _dobController.text =
            studentDetails['DOB']; // Make sure this is in DD/MM/YYYY format
        _casteController.text = studentDetails['Caste'];

        setState(() {
          _statusMessage = "Student found! You can now update the details.";
        });
      } else {
        // If student is not found, clear the text fields
        _nameController.clear();
        _classController.clear();
        _fatherNameController.clear();
        _phoneController.clear();
        _dobController.clear();
        _casteController.clear();

        setState(() {
          _statusMessage = "Student not found.";
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

  // Function to handle form submission (update details)
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

    // Make the HTTP POST request to update student details
    try {
      final response = await http.post(
        Uri.parse(
            'http://localhost/fees/update_student.php'), // Replace with your PHP URL
        body: formData,
      );
      final responseData = json.decode(response.body);

      setState(() {
        _statusMessage = responseData['message'];
      });
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _emisController,
                          label: 'EMIS No',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter EMIS No';
                            }
                            return null;
                          },
                        ),
                        ElevatedButton(
                          onPressed: _loadStudentDetails,
                          child: const Text('Load Student Details'),
                        ),
                        _buildTextField(
                          controller: _nameController,
                          label: 'Name',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter name';
                            }
                            return null;
                          },
                        ),
                        _buildTextField(
                          controller: _classController,
                          label: 'Class',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter class';
                            }
                            return null;
                          },
                        ),
                        _buildTextField(
                          controller: _fatherNameController,
                          label: 'Father\'s Name',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter father\'s name';
                            }
                            return null;
                          },
                        ),
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter phone number';
                            }
                            return null;
                          },
                        ),
                        _buildDateField(
                          controller: _dobController,
                          label: 'Date of Birth',
                        ),
                        _buildTextField(
                          controller: _casteController,
                          label: 'Caste',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter caste';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 20),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            backgroundColor: Colors.blueAccent,
                          ),
                          child: _isSubmitting
                              ? CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Submit',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_statusMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _statusMessage.contains("exists")
                          ? Colors.red.shade200
                          : Colors.green.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _statusMessage.contains("exists")
                            ? Colors.red
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey.shade200,
        ),
        validator: validator,
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey.shade200,
          suffixIcon: Icon(Icons.calendar_today),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter date of birth';
          }
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
    );
  }
}

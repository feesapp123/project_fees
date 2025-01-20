import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Add New Class',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AddClassScreen(),
    );
  }
}

class AddClassScreen extends StatefulWidget {
  @override
  _AddClassScreenState createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController _classNameController = TextEditingController();
  TextEditingController _totalFeeController = TextEditingController();
  TextEditingController _scholarshipAmountController = TextEditingController();
  TextEditingController _feePeriodController = TextEditingController();

  String _selectedMedium = 'Tamil';
  String _selectedFeePeriod = 'Monthly';
  bool _isLoading = false;

  // Function to handle the form submission
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Prepare data
      String className =
          _classNameController.text.toUpperCase(); // Convert to uppercase
      String totalFee = _totalFeeController.text;
      String scholarshipAmount = _scholarshipAmountController.text;

      // Send data to the backend using HTTP POST request
      final response = await http.post(
        Uri.parse('http://localhost/fees/insert_class.php'),
        body: {
          'className': className,
          'medium': _selectedMedium,
          'totalFee': totalFee,
          'scholarshipAmount':
              scholarshipAmount.isEmpty ? '0.00' : scholarshipAmount,
          'feePeriod': _selectedFeePeriod,
        },
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        // Show a success message
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(data['message'])));
      } else {
        // Show an error message
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to add class')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Class'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Class Name
              Card(
                color: Colors.lightBlue[50],
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _classNameController,
                    decoration: InputDecoration(
                      labelText: 'Class Name (e.g., 5A, 6B)',
                      icon: Icon(Icons.class_, color: Colors.blue),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a class name';
                      }
                      if (!RegExp(r'^[0-9]+[A-Za-z]$').hasMatch(value)) {
                        return 'Class name should be in the format "5A", "6B", etc.';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              // Medium Dropdown
              Card(
                color: Colors.lightGreen[50],
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButtonFormField<String>(
                    value: _selectedMedium,
                    decoration: InputDecoration(
                      labelText: 'Medium',
                      icon: Icon(Icons.language, color: Colors.green),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedMedium = value!;
                      });
                    },
                    items: ['Tamil', 'English']
                        .map((medium) => DropdownMenuItem(
                            value: medium, child: Text(medium)))
                        .toList(),
                  ),
                ),
              ),
              // Total Fee
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _totalFeeController,
                    decoration: InputDecoration(
                      labelText: 'Total Fee',
                      icon: Icon(Icons.attach_money, color: Colors.orange),
                    ),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          double.tryParse(value) == null ||
                          double.parse(value) <= 0) {
                        return 'Please enter a valid total fee';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              // Scholarship Amount
              Card(
                color: Colors.pink[50],
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _scholarshipAmountController,
                    decoration: InputDecoration(
                      labelText: 'Scholarship Amount (Optional)',
                      icon: Icon(Icons.money_off, color: Colors.pink),
                    ),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ),
              // Fee Period Dropdown
              Card(
                color: Colors.purple[50],
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButtonFormField<String>(
                    value: _selectedFeePeriod,
                    decoration: InputDecoration(
                      labelText: 'Fee Period',
                      icon: Icon(Icons.calendar_today, color: Colors.purple),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedFeePeriod = value!;
                      });
                    },
                    items: ['Monthly', 'Quarterly', 'Annually']
                        .map((period) => DropdownMenuItem(
                            value: period, child: Text(period)))
                        .toList(),
                  ),
                ),
              ),
              // Submit Button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _submitForm,
                        child: Text('Add Class'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 234, 226, 248),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

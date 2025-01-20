import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PromoteStudentScreen extends StatefulWidget {
  @override
  _PromoteStudentScreenState createState() => _PromoteStudentScreenState();
}

class _PromoteStudentScreenState extends State<PromoteStudentScreen> {
  List<dynamic> students = [];
  List<String> availableClasses = [];
  List<String> higherClasses = [];
  List<String> academicYears = [];
  Set<int> selectedStudents = {};
  String _statusMessage = '';
  String _selectedClass = '';
  String _selectedNextClass = '';
  String _selectedAcademicYear = '';
  bool _isLoading = false;
  bool _isLoadingClasses = true;

  @override
  void initState() {
    super.initState();
    fetchClassesAndYears();
  }

  Future<void> fetchClassesAndYears() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost/fees/fetch_class_prom.php'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            availableClasses = List<String>.from(data['all_classes']);
            academicYears = List<String>.from(data['academic_years']);
            _isLoadingClasses = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error fetching classes: $e';
        _isLoadingClasses = false;
      });
    }
  }

  Future<void> fetchHigherClasses(String currentClass) async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://localhost/fees/fetch_class_prom.php?current_class=$currentClass'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            higherClasses = List<String>.from(data['higher_classes']);
          });
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error fetching higher classes: $e';
      });
    }
  }

  Future<void> fetchStudents() async {
    if (_selectedClass.isEmpty || _selectedAcademicYear.isEmpty) {
      setState(() {
        _statusMessage = 'Please select both class and academic year';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      selectedStudents.clear();
    });

    try {
      final response = await http.get(
        Uri.parse(
          'http://localhost/fees/fetch_stud_prom.php?class=$_selectedClass&academic_year=$_selectedAcademicYear',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            students = data['data'];
            _isLoading = false;
          });
          await fetchHigherClasses(_selectedClass);
        } else {
          setState(() {
            _statusMessage = data['message'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Promote Students'),
        elevation: 2,
      ),
      body: _isLoadingClasses
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Class and Academic Year',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: 'Current Class',
                                      border: OutlineInputBorder(),
                                    ),
                                    value: _selectedClass.isEmpty
                                        ? null
                                        : _selectedClass,
                                    items: availableClasses.map((className) {
                                      return DropdownMenuItem(
                                        value: className,
                                        child: Text(className),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedClass = value!;
                                        _selectedNextClass = '';
                                      });
                                    },
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: 'Academic Year',
                                      border: OutlineInputBorder(),
                                    ),
                                    value: _selectedAcademicYear.isEmpty
                                        ? null
                                        : _selectedAcademicYear,
                                    items: academicYears.map((year) {
                                      return DropdownMenuItem(
                                        value: year,
                                        child: Text(year),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedAcademicYear = value!;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Center(
                              child: ElevatedButton.icon(
                                icon: Icon(Icons.search),
                                label: Text('Load Students'),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                ),
                                onPressed: fetchStudents,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isLoading)
                      Center(child: CircularProgressIndicator())
                    else if (students.isNotEmpty) ...[
                      SizedBox(height: 24),
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Students List',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineLarge,
                                  ),
                                  Text(
                                    '${students.length} students found',
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: students.length,
                                itemBuilder: (context, index) {
                                  final student = students[index];
                                  return Card(
                                    elevation: 2,
                                    margin: EdgeInsets.symmetric(vertical: 4),
                                    child: CheckboxListTile(
                                      title: Text(
                                        student['StudentName'],
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('EMIS: ${student['EMISNo']}'),
                                          Text(
                                            'Fees Status: ${student['PaymentStatus']}',
                                            style: TextStyle(
                                              color: student['PaymentStatus'] ==
                                                      'Paid'
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                      value: selectedStudents
                                          .contains(student['StudentID']),
                                      onChanged: (bool? value) {
                                        setState(() {
                                          if (value!) {
                                            selectedStudents
                                                .add(student['StudentID']);
                                          } else {
                                            selectedStudents
                                                .remove(student['StudentID']);
                                          }
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Next Class for Promotion',
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
                              ),
                              SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'Next Class',
                                  border: OutlineInputBorder(),
                                ),
                                value: _selectedNextClass.isEmpty
                                    ? null
                                    : _selectedNextClass,
                                items: higherClasses.map((className) {
                                  return DropdownMenuItem(
                                    value: className,
                                    child: Text(className),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedNextClass = value!;
                                  });
                                },
                              ),
                              SizedBox(height: 16),
                              Center(
                                child: ElevatedButton.icon(
                                  icon: Icon(Icons.arrow_forward),
                                  label: Text('Promote Selected Students'),
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                  ),
                                  onPressed: promoteStudents,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else if (_statusMessage.isNotEmpty)
                      Center(
                        child: Text(
                          _statusMessage,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  // Promote selected students to the next class
  Future<void> promoteStudents() async {
    if (_selectedNextClass.isEmpty) {
      setState(() {
        _statusMessage = 'Please select a next class for promotion.';
      });
      return;
    }

    if (selectedStudents.isEmpty) {
      setState(() {
        _statusMessage = 'Please select at least one student to promote.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost/fees/promote_students.php'),
        body: json.encode({
          'students': selectedStudents.toList(),
          'next_class': _selectedNextClass,
          'academic_year': _selectedAcademicYear,
        }),
      );

      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        setState(() {
          _statusMessage = 'Students promoted successfully!';
          _isLoading = false;
          students.clear();
          selectedStudents.clear();
        });
      } else {
        setState(() {
          _statusMessage =
              data['message'] ?? 'An error occurred while promoting students.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }
}

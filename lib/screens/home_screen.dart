import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Import modularized widgets
import 'SearchWidget.dart';
import 'widgets/ClassDetailsDialog.dart';
import 'widgets/ClassesListWidget.dart';
import 'widgets/StudentsListWidget.dart';
import 'widgets/ProfileAvatarWidget.dart';
import 'StudentProfileScreen.dart';
import 'admin_dashboard.dart'; // Import Admin Dashboard for admin access

class HomeScreen extends StatefulWidget {
  final String email;
  final String role;

  const HomeScreen({super.key, required this.email, required this.role});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  List<String> classes = [];
  List<Map<String, dynamic>> students = [];
  String searchQuery = '';
  bool isSearchingClasses = true;
  List<dynamic> searchResults = [];
  bool isLoading = true;
  final double classFees = 0; // To store the fetched class fees

  @override
  @override
  void initState() {
    super.initState();
    // Automatically navigate to AdminDashboard if the role is admin
    if (widget.role == 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AdminDashboard(
                email: widget.email,
                role: widget.role,
              ),
            ),
          );
        }
      });
    } else {
      _fetchClasses(); // Fetch classes for non-admin users
      fetchStudents(); // Fetch students for non-admin users
    }
  }

  // Fetch the list of classes from PHP backend
  Future<void> _fetchClasses() async {
    try {
      final response =
          await http.get(Uri.parse('http://localhost/fees/fetch_classes.php'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          classes = List<String>.from(data);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        throw Exception('Failed to fetch classes');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('Error fetching classes: $e');
    }
  }

  // Fetch the list of students by class name from the PHP backend
  Future<void> _fetchStudentsByClass(String className) async {
    try {
      final response = await http.get(Uri.parse(
          'http://localhost/fees/fetch_student.php?className=$className'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          students =
              List<Map<String, dynamic>>.from(data); // Update students list
        });
      } else {
        throw Exception('Failed to fetch students for this class');
      }
    } catch (e) {
      debugPrint('Error fetching students for class $className: $e');
    }
  }

  // Fetch the list of students from PHP backend
  // Fetch the list of students from PHP backend
  // Fetch the list of students from PHP backend
  Future<void> fetchStudents() async {
    try {
      final response = await http.get(Uri.parse(
          "http://localhost/fees/fetch_students.php?search=$searchQuery"));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint(
            'Raw response: $data'); // This prints the whole decoded response

        // Check if 'data' exists and is a list
        if (data != null && data['data'] != null && data['data'] is List) {
          setState(() {
            students = List<Map<String, dynamic>>.from(data['data']);
          });
        } else {
          debugPrint("No valid 'data' or 'students' found in response.");
          setState(() {
            students = []; // Empty list in case of invalid response
          });
        }
      } else {
        debugPrint("Error: ${response.statusCode}");
        setState(() {
          students = []; // Empty list if the status code isn't 200
        });
      }
    } catch (e) {
      debugPrint("Error fetching students: $e");
      setState(() {
        students = []; // Empty list in case of error
      });
    }
  }

  // Fetch class fee details for a specific class from PHP backend
  Future<Map<String, dynamic>> _fetchClassFees(String className) async {
    try {
      final response = await http.post(
        Uri.parse(
            'http://localhost/fees/get_fees.php'), // Assuming this PHP endpoint provides fee details
        body: {'class': className},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Fetched Class Fees: $data');
        return Map<String, dynamic>.from(data[0]);

// Assuming one result for the class
      } else {
        throw Exception('Failed to fetch class fees');
      }
    } catch (e) {
      debugPrint('Error fetching class fees: $e');
      return {}; // Return an empty map in case of error
    }
  }

  // Search logic to filter students and classes
  void _search(String query) {
    setState(() {
      searchQuery = query;
      if (isSearchingClasses) {
        searchResults = classes
            .where((classItem) =>
                classItem.toLowerCase().contains(query.toLowerCase()))
            .toList();
      } else {
        fetchStudents();
        searchResults = students
            .where((student) => student['StudentName']
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // Toggle between searching classes and students
  void _toggleSearchType() {
    setState(() {
      isSearchingClasses = !isSearchingClasses;
      searchResults.clear();
    });
  }

  void _showStudentProfile(BuildContext context, Map<String, dynamic> student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentProfileScreen(
          student: student, // Pass the selected student
        ),
      ),
    );
  }

  // Show class details dialog with fees
  // Show class details dialog with fees
  void _showClassDetails(BuildContext context, String className) {
    _fetchClassFees(className).then((classFeeData) {
      // Fetch students for this class
      _fetchStudentsByClass(className).then((_) {
        List<Map<String, dynamic>> studentsInClass =
            students.where((student) => student['Class'] == className).toList();

        debugPrint('Class Name: $className');
        debugPrint('Class Fee Data: $classFeeData');
        debugPrint('Students in Class: ${studentsInClass.length}');

        showDialog(
          context: context,
          builder: (context) {
            return ClassDetailsDialog(
              className: className,
              studentsInClass: studentsInClass,
              searchQuery: searchQuery,
              onStudentTapped: (student) {
                showDialog(
                  context: context,
                  builder: (context) => StudentProfileScreen(student: student),
                );
              },
            );
          },
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(" FEES MANAGEMENT APPLICATION Dashboard"),
        backgroundColor: Colors.deepPurpleAccent,
        actions: [
          ProfileAvatarWidget(),
        ],
      ),
      body: Column(
        children: [
          // Search bar and toggle
          SearchWidget(
            onSearch: _search,
            isSearchingClasses: isSearchingClasses,
            onToggleSearchType: _toggleSearchType,
          ),
          // Display Classes or Students Based on Search Results
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      if (isSearchingClasses)
                        ClassesListWidget(
                          classes: searchResults.isEmpty
                              ? List<String>.from(classes)
                              : List<String>.from(searchResults),
                          onClassTapped: (className) => _showClassDetails(
                              context, className), // Pass function reference
                        ),
                      if (!isSearchingClasses)
                        StudentsListWidget(
                          students: searchResults.isEmpty
                              ? List<Map<String, dynamic>>.from(students)
                              : List<Map<String, dynamic>>.from(searchResults),
                          onStudentTapped: (student) {
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                child: StudentProfileScreen(
                                  student:
                                      student, // Pass the student to the profile screen
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
          )
        ],
      ),
    );
  }
}

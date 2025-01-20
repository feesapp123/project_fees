import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:project_fees/screens/promotestudent_screen.dart';
import 'dart:convert';

// Import modularized widgets
import 'SearchWidget.dart';
import 'widgets/ClassDetailsDialog.dart';
import 'widgets/ClassesListWidget.dart';
import 'widgets/StudentsListWidget.dart';
import 'widgets/ProfileAvatarWidget.dart';
import 'StudentProfileScreen.dart';
import 'manage_users_screen.dart';
import 'mark_payment_screen.dart';
import 'set_fees_screen.dart';
import 'edit_student_details_screen.dart';
import 'upload_file_screen.dart';
import 'addclass_screen.dart';

class AdminDashboard extends StatefulWidget {
  final String email;
  final String role;

  const AdminDashboard({super.key, required this.email, required this.role});

  @override
  AdminDashboardState createState() => AdminDashboardState();
}

class AdminDashboardState extends State<AdminDashboard> {
  String searchQuery = '';
  bool isSearchingClasses = true;
  List<dynamic> searchResults = [];
  bool isLoading = true;
  List<String> classes = [];
  List<Map<String, dynamic>> students = [];

  @override
  void initState() {
    super.initState();
    _fetchClasses(); // Fetch classes initially
  }

  void _showClassDetails(
      BuildContext context, String className, String searchQuery) {
    _fetchClassFees(className).then((classFeeData) {
      // Fetch students based on class name
      _fetchStudentsByClass(className).then((studentsInClass) {
        showDialog(
          context: context,
          builder: (context) {
            return ClassDetailsDialog(
              className: className,
              studentsInClass: studentsInClass,
              searchQuery: searchQuery, // Pass the searchQuery here
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

  // Fetch class fees (No change)
  Future<Map<String, dynamic>> _fetchClassFees(String className) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost/fees/fetch_fees.php?className=$className'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final classData = data.firstWhere(
          (entry) => entry['Class'] == className,
          orElse: () => null,
        );
        return classData ?? {};
      } else {
        throw Exception('Failed to fetch class fees');
      }
    } catch (e) {
      return {};
    }
  }

  // Fetch classes (No change)
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
        throw Exception('Failed to fetch classes');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('Error fetching classes: $e');
    }
  }

  // Fetch students based on search query (No change)
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

  // Fetch students based on class name (modified)
  Future<List<Map<String, dynamic>>> _fetchStudentsByClass(
      String className) async {
    try {
      final response = await http.get(Uri.parse(
          'http://localhost/fees/fetch_student.php?className=$className'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to fetch students');
      }
    } catch (e) {
      debugPrint('Error fetching students: $e');
      return [];
    }
  }

  // Search logic (No change)
  void _search(String query) {
    setState(() {
      searchQuery = query;
      if (isSearchingClasses) {
        searchResults = classes
            .where((classItem) =>
                classItem.toLowerCase().contains(query.toLowerCase()))
            .toList();
      } else {
        fetchStudents(); // Fetch students based on search query
        searchResults = students
            .where((student) => student['StudentName']
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // Toggle between searching classes and students (No change)
  void _toggleSearchType() {
    setState(() {
      isSearchingClasses = !isSearchingClasses;
      searchResults.clear(); // Clear previous search results
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.deepPurpleAccent,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [
          ProfileAvatarWidget(),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent,
              ),
              child: Text('Admin Menu', style: TextStyle(color: Colors.white)),
            ),
            ListTile(
              title: const Text('Files Upload'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UploadFileScreen()),
                );
              },
            ),
            ListTile(
              title: const Text('Edit Students'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => EditStudentDetailsScreen()),
                );
              },
            ),
            ListTile(
              title: const Text('Promote Students'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PromoteStudentScreen()),
                );
              },
            ),
            ListTile(
              title: const Text('Mark Payments'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MarkPaymentScreen()),
                );
              },
            ),
            ListTile(
              title: const Text('Add Class'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddClassScreen()),
                );
              },
            ),
            ListTile(
              title: const Text('Set Fees'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SetFeesScreen()),
                );
              },
            ),
            ListTile(
              title: const Text('Manage User'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManageUsersScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          SearchWidget(
            onSearch: _search,
            isSearchingClasses: isSearchingClasses,
            onToggleSearchType: _toggleSearchType,
          ),
          Expanded(
            child: Column(
              children: [
                if (isSearchingClasses)
                  ClassesListWidget(
                    classes: searchResults.isEmpty
                        ? List<String>.from(classes)
                        : List<String>.from(searchResults),
                    onClassTapped: (className) =>
                        _showClassDetails(context, className, searchQuery),
                  ),
                if (!isSearchingClasses)
                  StudentsListWidget(
                    students: searchResults.isEmpty
                        ? List<Map<String, dynamic>>.from(students)
                        : List<Map<String, dynamic>>.from(searchResults),
                    onStudentTapped: (student) {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            StudentProfileScreen(student: student),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

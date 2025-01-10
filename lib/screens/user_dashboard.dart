import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'widgets/ClassesListWidget.dart'; // Widget to display classes
import 'widgets/StudentsListWidget.dart'; // Widget to display students

class UserDashboard extends StatefulWidget {
  final String email;
  final String role;

  const UserDashboard({super.key, required this.email, required this.role});

  @override
  UserDashboardState createState() => UserDashboardState();
}

class UserDashboardState extends State<UserDashboard> {
  String searchQuery = '';
  bool isSearchingClasses = true;
  List<dynamic> searchResults = [];
  List<String> classes = [];
  List<Map<String, String>> students = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => isLoading = true);

    try {
      final classesResponse = await http.get(
        Uri.parse('http://localhost/fees/fetch_classes.php'),
      );
      final studentsResponse = await http.get(
        Uri.parse('http://localhost/fees/fetch_students.php'),
      );

      if (classesResponse.statusCode == 200 &&
          studentsResponse.statusCode == 200) {
        final classesData = jsonDecode(classesResponse.body);
        final studentsData = jsonDecode(studentsResponse.body);

        setState(() {
          classes = List<String>.from(classesData['classes']);
          students = List<Map<String, String>>.from(studentsData['students']);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch data');
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorDialog('An error occurred: $e');
    }
  }

  void _search(String query) {
    setState(() {
      searchQuery = query;
      if (isSearchingClasses) {
        searchResults = classes
            .where((classItem) =>
                classItem.toLowerCase().contains(query.toLowerCase()))
            .toList();
      } else {
        searchResults = students
            .where((student) =>
                student['name']!.toLowerCase().contains(query.toLowerCase()) ||
                student['email']!.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _toggleSearchType() {
    setState(() {
      isSearchingClasses = !isSearchingClasses;
      searchResults.clear();
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Dashboard"),
        backgroundColor: Colors.deepPurpleAccent,
        leading: null, // Remove the hamburger icon
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              // Implement logout functionality
            },
          ),
        ],
      ),
      drawer: null, // Ensure no drawer is attached to remove the icon
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Name: ${widget.email}', // Fix: Correct property to display email
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Role: ${widget.role}', // Fix: Correct property to display role
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: TextField(
                    onChanged: _search,
                    decoration: InputDecoration(
                      labelText: isSearchingClasses
                          ? 'Search Classes'
                          : 'Search Students',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isSearchingClasses ? Icons.group : Icons.class_,
                        ),
                        onPressed: _toggleSearchType,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      if (isSearchingClasses)
                        ClassesListWidget(
                          classes: searchResults.isEmpty
                              ? classes
                              : searchResults.cast<String>(),
                          onClassTapped: (className) {
                            debugPrint("Class tapped: $className");
                          },
                        ),
                      if (!isSearchingClasses)
                        StudentsListWidget(
                          students: searchResults.isEmpty
                              ? students
                              : List<Map<String, String>>.from(searchResults),
                          onStudentTapped: (student) {
                            debugPrint("Student tapped: ${student['name']}");
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

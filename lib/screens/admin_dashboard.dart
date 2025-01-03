import 'package:flutter/material.dart';
import 'upload_file_screen.dart';
import 'set_fees_screen.dart';
import 'edit_student_details_screen.dart';

class AdminDashboard extends StatelessWidget {
  final List<String> classes;

  const AdminDashboard({
    super.key,
    required this.classes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fees Management - Admin Dashboard"),
      ),
      drawer: Drawer(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text("Upload Files"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const UploadFileScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text("Set Fees"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SetFeesScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("Edit Student Details"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EditStudentDetailsScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Text('Welcome to Admin Dashboard'),
      ),
    );
  }
}

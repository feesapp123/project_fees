import 'package:flutter/material.dart';

class UserDashboard extends StatelessWidget {
  final String name;
  final String email;
  final List<String> classes;

  const UserDashboard({
    super.key,
    required this.name,
    required this.email,
    required this.classes,
  });

  void _onClassTap(BuildContext context, String className) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Class Selected"),
        content: Text("You selected class $className."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fees Management - User Dashboard"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Welcome, $name",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Email: $email"),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: const Text(
              "Available Classes:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: classes.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(classes[index]),
                  onTap: () => _onClassTap(context, classes[index]),
                  tileColor: const Color.fromARGB(
                      255, 249, 245, 245), // Optional styling
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

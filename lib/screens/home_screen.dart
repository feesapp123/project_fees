import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'admin_dashboard.dart'; // Import Admin Dashboard UI
import 'user_dashboard.dart'; // Import User Dashboard UI

class HomeScreen extends StatefulWidget {
  final String email; // Accept email in the constructor
  final String role;
  const HomeScreen(
      {super.key,
      required this.email,
      required this.role}); // Ensure the email is passed when initializing

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> classes = [
    '6A',
    '6B',
    '7A',
    '7B',
    '8A',
    '8B',
    '9A',
    '9B',
    '10'
  ];

  Map<String, String>? user; // User data fetched from the database
  bool isLoading = true; // To handle loading state
  String errorMessage = ""; // To display errors

  @override
  void initState() {
    super.initState();
    _fetchUserData(widget.email); // Use the email passed to the HomeScreen
  }

  Future<void> _fetchUserData(String email) async {
    try {
      final response = await http.post(
        Uri.parse(
            'http://localhost/fees/fetch_user.php'), // Use the correct URL for your environment
        body: {'email': email},
      );

      debugPrint("Response Status: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (mounted) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data['error'] != null) {
            setState(() {
              errorMessage = data['error'];
              isLoading = false;
            });
          } else {
            setState(() {
              user = {
                'name': data['UserName'],
                'email': data['email'],
                'role': data['role'],
              };
              isLoading = false;
            });
          }
        } else {
          setState(() {
            errorMessage = "Server error: ${response.statusCode}";
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        debugPrint("Error details: $e"); // Add this for detailed error logging
        setState(() {
          errorMessage = "Failed to connect to the server: $e";
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Scaffold(
        body: Center(child: Text(errorMessage)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Fees Management Dashboard"),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              backgroundImage: AssetImage('assets/profile.png'),
              radius: 30,
            ),
            onPressed: _showProfileDialog,
          ),
        ],
      ),
      body: _getRoleBasedDashboard(),
    );
  }

  Widget _getRoleBasedDashboard() {
    if (user == null) {
      return const Center(child: Text("User data not loaded."));
    }

    final role = user?['role'] ?? 'user'; // Default to 'user' if 'role' is null
    switch (role) {
      case 'admin':
        return AdminDashboard(classes: classes); // Pass the required classes
      case 'user':
        return UserDashboard(
          name: user?['name'] ?? 'Unknown',
          email: user?['email'] ?? 'Unknown',
          classes: classes,
        ); // Pass the user data and classes
      default:
        return const Center(
          child: Text(
            "Invalid user role!",
            style: TextStyle(color: Colors.red, fontSize: 18),
          ),
        );
    }
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Profile"),
        content: Row(
          children: [
            const CircleAvatar(
              backgroundImage: AssetImage('assets/profile.png'),
              radius: 40,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(user?['name'] ?? 'No Name'),
                Text(user?['email'] ?? 'No Email'),
                Text(user?['role'] ?? 'No Role'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}

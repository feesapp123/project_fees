import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ProfileAvatarWidget extends StatefulWidget {
  const ProfileAvatarWidget({super.key});

  @override
  State<ProfileAvatarWidget> createState() => _ProfileAvatarWidgetState();
}

class _ProfileAvatarWidgetState extends State<ProfileAvatarWidget> {
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('userEmail');
    });
    debugPrint('Loaded email: $userEmail');
  }

  Future<void> _fetchAndDisplayUserDetails(BuildContext context) async {
    if (userEmail == null) {
      _showErrorDialog(context, 'User email/phone not available');
      return;
    }

    const String apiUrl = 'http://localhost/fees/fetch_user.php';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {'email': userEmail},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['error'] != null) {
          _showErrorDialog(context, data['error']);
        } else {
          _showUserDetailsDialog(
            context,
            data['UserName'] ?? 'Unknown',
            data['email'] ?? 'Unknown',
            data['role'] ?? 'Unknown',
            data['Mobile'] ?? 'Unknown',
          );
        }
      } else {
        _showErrorDialog(context, 'Failed to fetch user details');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(context, 'An error occurred: $e');
    }
  }

  void _showUserDetailsDialog(BuildContext context, String userName,
      String email, String role, String phone) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'User Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(Icons.person, 'Name', userName),
              _buildDetailRow(Icons.email, 'Email', email),
              _buildDetailRow(Icons.verified_user, 'Role', role),
              _buildDetailRow(Icons.phone, 'Phone', phone),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                await _logout(context);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    const String logoutUrl = 'http://localhost/fees/logout.php';

    try {
      final response = await http.post(Uri.parse(logoutUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.remove('userEmail');

          Navigator.pushReplacementNamed(context, '/');
        } else {
          _showErrorDialog(context, 'Failed to logout');
        }
      } else {
        _showErrorDialog(context, 'Logout failed. Please try again later.');
      }
    } catch (e) {
      _showErrorDialog(context, 'An error occurred during logout: $e');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Error',
            style: TextStyle(color: Colors.redAccent),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurpleAccent),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.grey,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _fetchAndDisplayUserDetails(context),
      child: CircleAvatar(
        backgroundColor: Colors.deepPurpleAccent,
        radius: 20,
        child: const Icon(
          Icons.person,
          color: Colors.white,
        ),
      ),
    );
  }
}

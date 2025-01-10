import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  _ManageUsersScreenState createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;

  // Fetch users from backend
  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response =
          await http.get(Uri.parse('http://localhost/fees/get_users.php'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _users = List<Map<String, dynamic>>.from(data);
          });
        }
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching users: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  // Remove user from the database
  Future<void> _removeUser(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost/fees/remove_user.php'),
        body: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'success') {
          if (mounted) {
            setState(() {
              _users.removeWhere((user) => user['id'] == userId);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("User removed successfully")),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Failed to remove user")),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error removing user: $e")),
        );
      }
    }
  }

  // Make user an admin
  Future<void> _makeAdmin(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost/fees/make_admin.php'),
        body: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'success') {
          if (mounted) {
            setState(() {
              final userIndex =
                  _users.indexWhere((user) => user['id'] == userId);
              _users[userIndex]['role'] = 'admin';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("User promoted to admin")),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Failed to promote user")),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error promoting user: $e")),
        );
      }
    }
  }

  // Demote admin to user
  Future<void> _demoteAdmin(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost/fees/demote_admin.php'),
        body: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'success') {
          if (mounted) {
            setState(() {
              final userIndex =
                  _users.indexWhere((user) => user['id'] == userId);
              _users[userIndex]['role'] = 'user';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Admin demoted to user")),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Failed to demote admin")),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error demoting admin: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      title: Text(
                        user['UserName'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                          'Email: ${user['email']} | Mobile: ${user['Mobile']} | Role: ${user['role']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Delete button with tooltip
                          Tooltip(
                            message: 'Delete User',
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeUser(user['id']),
                            ),
                          ),
                          // Promote button with tooltip
                          if (user['role'] != 'admin')
                            Tooltip(
                              message: 'Promote to Admin',
                              child: IconButton(
                                icon: const Icon(
                                  Icons.admin_panel_settings,
                                  color: Colors.green,
                                ),
                                onPressed: () => _makeAdmin(user['id']),
                              ),
                            ),
                          // Demote button with tooltip
                          if (user['role'] == 'admin')
                            Tooltip(
                              message: 'Demote to User',
                              child: IconButton(
                                icon: const Icon(
                                  Icons.person_remove,
                                  color: Colors.orange,
                                ),
                                onPressed: () => _demoteAdmin(user['id']),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

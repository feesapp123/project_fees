import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  RegisterPageState createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _mobileController =
      TextEditingController(); // Mobile number controller
  bool _isLoading = false;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();
      String userName = _userNameController.text.trim();
      String mobile = _mobileController.text.trim(); // Mobile number

      try {
        var uri =
            'http://localhost/fees/register_user.php'; // Backend script to register user
        final response = await http.post(
          Uri.parse(uri),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {
            'email': email,
            'password': password,
            'user_name': userName,
            'role': 'user', // Default role as user
            'mobile': mobile, // Include mobile number in request body
          },
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          if (responseData['status'] == 'success') {
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("User registered successfully")),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text(responseData['message'] ?? 'Registration failed'),
                ),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Server error. Please try again.")),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create New User"),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: AnimatedOpacity(
            opacity: _isLoading ? 0.4 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: [
                      // Username Input with Icon
                      TextFormField(
                        controller: _userNameController,
                        decoration: const InputDecoration(
                          labelText: "Username",
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter a username";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Email Input with Icon
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter an email";
                          } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                              .hasMatch(value)) {
                            return "Invalid email address";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Password Input with Icon
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Password",
                          prefixIcon: Icon(Icons.lock),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter a password";
                          } else if (value.length < 6) {
                            return "Password must be at least 6 characters long";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Mobile Number Input with Icon
                      TextFormField(
                        controller: _mobileController,
                        decoration: const InputDecoration(
                          labelText: "Mobile Number",
                          prefixIcon: Icon(Icons.phone),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter a mobile number";
                          } else if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                            return "Please enter a valid 10-digit mobile number";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),

                      // Register Button
                      ElevatedButton(
                        onPressed: _register,
                        child: const Text("Register"),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

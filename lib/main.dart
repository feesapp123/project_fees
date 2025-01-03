import 'package:flutter/material.dart';
import 'package:logger/logger.dart'; // Import the logger package
import 'package:project_fees/screens/home_screen.dart';
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create a logger instance
  final logger = Logger();

  try {
    // Application-specific initialization logic can go here if needed
  } catch (e) {
    // Replace print with logger for better logging
    logger.e("Error during initialization: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fees Management System',
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/dashboard') {
          final Map<String, String> arguments =
              settings.arguments as Map<String, String>;

          final String email = arguments['email']!;
          final String role = arguments['role'] ??
              'user'; // Default to 'user' if role is missing

          return MaterialPageRoute(
            builder: (context) => HomeScreen(email: email, role: role),
          );
        }
        return null;
      },
    );
  }
}

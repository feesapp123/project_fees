import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/dashboardpage.dart';

void main() {
  runApp(const MyApp()); // Added `const` here
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Ensured `const` is consistent

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fees Management System',
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(), // Added `const`
        '/dashboard': (context) => const DashboardPage(), // Added `const`
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'pages/login_page.dart';
import 'screens/admin_dashboard.dart';
import 'screens/user_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final logger = Logger();
  try {
    // Application-specific initialization logic
  } catch (e) {
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
        '/admin_dashboard': (context) =>
            const AdminDashboard(email: '', role: ''),
        '/user_dashboard': (context) =>
            const UserDashboard(email: '', role: ''),
      },
      onGenerateRoute: (settings) {
        // Handle navigation with arguments
        if (settings.name == '/admin_dashboard') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => AdminDashboard(
              email: args['email'] ?? '',
              role: args['role'] ?? 'admin',
            ),
          );
        }
        if (settings.name == '/user_dashboard') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => UserDashboard(
              email: args['email'] ?? '',
              role: args['role'] ?? 'user',
            ),
          );
        }
        return null;
      },
    );
  }
}

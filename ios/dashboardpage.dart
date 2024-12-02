import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key}); // Added const to constructor

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"), // Use const for the Text widget
      ),
      body: const Center(
        child:
            Text("Welcome to the Dashboard!"), // Use const for the Text widget
      ),
    );
  }
}

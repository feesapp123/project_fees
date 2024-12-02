import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key}); // Use super parameter

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"), // Use const
      ),
      body: const Center(
        child: Text("Welcome to the Dashboard!"), // Use const
      ),
    );
  }
}

import 'package:flutter/material.dart';

class UploadFileScreen extends StatelessWidget {
  const UploadFileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Files")),
      body: const Center(child: Text("Upload File Screen")),
    );
  }
}

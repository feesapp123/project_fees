import 'package:flutter/material.dart';

class ClassesListWidget extends StatelessWidget {
  final List<String> classes;
  final Function(String) onClassTapped;

  const ClassesListWidget({
    super.key,
    required this.classes,
    required this.onClassTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: classes.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(classes[index]),
            onTap: () => onClassTapped(classes[index]),
            tileColor: const Color.fromARGB(255, 249, 245, 245),
          );
        },
      ),
    );
  }
}

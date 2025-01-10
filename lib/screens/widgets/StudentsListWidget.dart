import 'package:flutter/material.dart';
import 'package:project_fees/screens/StudentProfileScreen.dart'; // Import the StudentProfileScreen

class StudentsListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> students;
  final Function(Map<String, dynamic>) onStudentTapped;

  const StudentsListWidget({
    super.key,
    required this.students,
    required this.onStudentTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: students.length,
        itemBuilder: (context, index) {
          final student = students[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () =>
                  onStudentTapped(student), // Call the onStudentTapped function
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Profile Icon or Placeholder
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.deepPurpleAccent,
                      child: Text(
                        student['StudentName']?[0] ?? '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Student Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${student['StudentName'] ?? 'Unknown Name'} - ${student['Class'] ?? 'Unknown Class'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Father\'s Name: ${student['FathersName'] ?? 'N/A'}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Payment Status: ${student['PaymentStatus'] ?? 'N/A'}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'EMIS No: ${student['EMISNo'] ?? 'N/A'}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Trailing Icon
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.deepPurpleAccent,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

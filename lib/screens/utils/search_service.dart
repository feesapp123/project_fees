import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class SearchService {
  // The base URL of your backend API (ensure this is the correct endpoint)
  static const String _baseUrl =
      'https://localhost/fees/search.php'; // Update with your real API URL

  // Function to search for students and classes
  static Future<List<dynamic>> search({
    required String query,
    required String searchType, // Either "student" or "class"
    String? filterClass,
  }) async {
    try {
      // Construct URL dynamically
      final Uri url =
          Uri.parse(_baseUrl).replace(path: '/search', queryParameters: {
        'query': query,
        'searchType': searchType,
        if (filterClass != null && filterClass.isNotEmpty)
          'filterClass': filterClass,
      });

      // Send the HTTP GET request
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Parse the JSON response
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch data');
      }
    } catch (e) {
      debugPrint('Search error: $e');
      throw Exception('Error during search');
    }
  }

  // Function to get detailed student information (e.g. grades)
  static Future<Map<String, dynamic>> getStudentDetails(int studentId) async {
    try {
      final Uri url = Uri.parse('$_baseUrl/student_details/$studentId');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch student details');
      }
    } catch (e) {
      debugPrint('Student details error: $e');
      throw Exception('Error during fetching student details');
    }
  }
}

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:excel/excel.dart' as excel;

class UploadFileScreen extends StatefulWidget {
  const UploadFileScreen({super.key});

  @override
  State<UploadFileScreen> createState() => _UploadFileScreenState();
}

class _UploadFileScreenState extends State<UploadFileScreen> {
  String? pickedFileName;
  Uint8List? fileBytes;
  bool isLoading = false;
  String? errorMessage;
  String? successMessage;
  List<String> errors = [];
  List<List<String>> previewData = [];
  final ScrollController _scrollController = ScrollController();

  // Add state for handling duplicates
  Set<String> existingEmisNumbers = {};
  Map<String, bool> duplicateHandling = {};
  bool skipAllDuplicates = false;
  bool updateAllDuplicates = false;

  // Add method to check for duplicates
  Future<void> _checkForDuplicates() async {
    if (previewData.isEmpty) return;

    // Find EMIS number column index
    final headers = previewData[0];
    final emisIndex =
        headers.indexWhere((header) => header.toLowerCase().contains('emis'));
    if (emisIndex == -1) return;
    //debugPrint('Emis Index:$emisIndex');
    // Extract EMIS numbers from preview data
    final emisNumbers = previewData
        .skip(1)
        .map((row) => row[emisIndex])
        .where((emis) => emis.isNotEmpty)
        .toList();
    debugPrint('$emisNumbers');

    try {
      // Check existing EMIS numbers with server
      final response = await http.post(
        Uri.parse('http://localhost/fees/check_emis.php'),
        body: json.encode({'emis_numbers': emisNumbers}),
        headers: {'Content-Type': 'application/json'},
      );

      final data = json.decode(response.body);

      setState(() {
        existingEmisNumbers = Set.from(data['existing_emis'] ?? []);
      });

      debugPrint(
          'Existing EMIS Numbers: $existingEmisNumbers'); // Debugging statement

      // If duplicates found, show dialog
      if (existingEmisNumbers.isNotEmpty) {
        await _showDuplicateHandlingDialog();
      }
    } catch (e) {
      _showError('Error checking for duplicates: $e');
    }
  }

  Future<void> _showDuplicateHandlingDialog() async {
    // Debugging statement to check if we reach this function

    return showDialog<void>(
      context: context,
      barrierDismissible:
          false, // Prevent dismissing the dialog by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Duplicate EMIS Numbers Found'),
          content: SingleChildScrollView(
            child: Column(
              children: existingEmisNumbers.map((emisNo) {
                return ListTile(
                  title: Text("EMIS No: $emisNo"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            duplicateHandling[emisNo] = false; // skip
                          });
                          Navigator.of(context)
                              .pop(); // Close dialog after update
                        },
                        child: const Text("Skip"),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            duplicateHandling[emisNo] = true; // update
                          });
                          Navigator.of(context)
                              .pop(); // Close dialog after update
                        },
                        child: const Text("Update"),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _showSuccess(String message) {
    setState(() {
      successMessage = message;
    });
  }

  void _showError(String message) {
    setState(() {
      errorMessage = message;
    });
  }

  void _parseExcel(Uint8List bytes) {
    var excelFile = excel.Excel.decodeBytes(bytes);
    if (excelFile != null) {
      setState(() {
        previewData.clear();
        for (var table in excelFile.tables.keys) {
          var rows = excelFile.tables[table]?.rows;
          if (rows != null) {
            // Convert rows of type List<Data?> to List<String>
            for (var row in rows) {
              previewData.add(
                row
                    .map((cell) =>
                        cell?.value?.toString() ??
                        '') // Ensure you use cell value
                    .toList(),
              );
            }
          }
        }
      });
      // Call _checkForDuplicates() after data is parsed
      _checkForDuplicates();
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null) {
        setState(() {
          pickedFileName = result.files.first.name;
          errorMessage = null;
          successMessage = null;
          errors = [];
          duplicateHandling.clear();
          skipAllDuplicates = false;
          updateAllDuplicates = false;

          if (kIsWeb) {
            fileBytes = result.files.first.bytes;
            _parseExcel(fileBytes!); // Parse the file immediately for preview
          }
        });
      }
    } catch (e) {
      _showError('Error picking file: $e');
    }
  }

  // Method to upload student data (after file preview)
  // Method to upload student data (after file preview)
  Future<void> uploadStudentData() async {
    if (previewData.isEmpty) {
      _showError('No data to upload. Please check the file preview.');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      successMessage = null;
      errors = [];
    });

    try {
      // Prepare duplicate handling options
      final duplicateOptions = {
        'skip_all': skipAllDuplicates,
        'update_all': updateAllDuplicates,
        'duplicate_handling': duplicateHandling,
      };

      // Extract student data from the preview (skip the header row)
      List<Map<String, String>> students = previewData
          .skip(1) // Skip header row
          .map((row) {
        return {
          'emis_number': row[1], // EMISNo
          'name': row[2], // StudentName
          'class': row[3], // Class
          'fathers_name': row[4], // FathersName
          'phone_number': row[7], // PhoneNumber
          'dob': row[8], // DOB (ensure this is in the correct format)
          'caste': row[13], // Caste
        };
      }).toList();

      //debugPrint('Students: $students');
      debugPrint('Sending Payload: ${json.encode({
            'students': students,
            'duplicate_options': duplicateOptions,
          })}');

      // Send data to the server
      var response = await http.post(
        Uri.parse('http://localhost/fees/insert_students.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'students': students,
          'duplicate_options': duplicateOptions,
        }),
      );

      // Use response.body to get the response content as a string
      final responseString = response.body;

      debugPrint('Response String: $responseString');

      // Handle the server response
      try {
        final responseData = json.decode(responseString);
        if (responseData['status'] == 'success') {
          _showSuccess(responseData['message']);

          // Show success SnackBar
          final insertedCount = responseData['inserted']?.length ?? 0;
          final updatedCount = responseData['updated']?.length ?? 0;
          final totalProcessed = insertedCount + updatedCount;

          String successMessage =
              'Successfully processed $totalProcessed students: $insertedCount inserted, $updatedCount updated.';

          // Show SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(successMessage)),
          );
        } else {
          _showError(responseData['message']);
        }

        if (responseData['errors'] != null) {
          setState(() {
            errors = List<String>.from(responseData['errors']);
          });
        }
      } catch (e) {
        _showError('Invalid server response: $responseString');
      }
    } catch (e) {
      _showError('Error uploading student data: ${e.toString()}');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Students Data"),
        elevation: 2,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Card(
              elevation: 4,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                padding: const EdgeInsets.all(32),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildUploadSection(),
                      const SizedBox(height: 32),
                      _buildDuplicateHandlingSection(), // Add duplicate handling UI
                      if (previewData.isNotEmpty) _buildPreviewSection(),
                      const SizedBox(height: 24),
                      if (errors.isNotEmpty) _buildErrorList(),
                    ],
                  ),
                ),
              )),
        ),
      ),
    );
  }

  // UI for duplicate handling
  Widget _buildDuplicateHandlingSection() {
    if (existingEmisNumbers.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Duplicate EMIS Numbers Found",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text("Skip All Duplicates"),
                  value: skipAllDuplicates,
                  onChanged: (value) {
                    setState(() {
                      skipAllDuplicates = value ?? false;
                      if (skipAllDuplicates) {
                        updateAllDuplicates = false;
                      }
                    });
                  },
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  title: const Text("Update All Duplicates"),
                  value: updateAllDuplicates,
                  onChanged: (value) {
                    setState(() {
                      updateAllDuplicates = value ?? false;
                      if (updateAllDuplicates) {
                        skipAllDuplicates = false;
                      }
                    });
                  },
                ),
              ),
            ],
          ),
          if (!skipAllDuplicates && !updateAllDuplicates)
            ...existingEmisNumbers.map((emisNo) {
              return ListTile(
                title: Text("EMIS No: $emisNo"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          duplicateHandling[emisNo] = false; // skip
                        });
                      },
                      child: const Text("Skip"),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          duplicateHandling[emisNo] = true; // update
                        });
                      },
                      child: const Text("Update"),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // UI for file upload section
  Widget _buildUploadSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.blue),
          const SizedBox(height: 16),
          const Text(
            "Upload Excel File",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Select an Excel file (.xlsx) containing student data",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.file_upload),
                label: const Text("Choose File"),
                onPressed: isLoading ? null : _pickFile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              if (pickedFileName != null)
                Text(
                  pickedFileName!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // UI for preview section
  Widget _buildPreviewSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[300]!),
      ),
      child: Column(
        children: [
          const Text(
            "Preview Data",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                for (var header in previewData.isNotEmpty ? previewData[0] : [])
                  DataColumn(label: Text(header)),
              ],
              rows: [
                for (var row in previewData.skip(1))
                  DataRow(
                    cells: [
                      for (var cell in row) DataCell(Text(cell)),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : uploadStudentData,
            child: isLoading
                ? const CircularProgressIndicator()
                : const Text("Upload Data"),
          ),
        ],
      ),
    );
  }

  // UI for error messages
  Widget _buildErrorList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Errors",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          ...errors.map((error) => Text(
                error,
                style: const TextStyle(color: Colors.red),
              )),
        ],
      ),
    );
  }
}

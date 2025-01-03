import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  ReportScreenState createState() =>
      ReportScreenState(); // State class matches here
}

class ReportScreenState extends State<ReportScreen> {
  // State class is now public
  List<String> reports = [];
  final String fetchReportsUrl = "http://localhost/fees/fetch-reports.php";
  final String downloadReportUrl = "http://localhost/fees/download-report.php";

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    try {
      final response = await http.get(Uri.parse(fetchReportsUrl));
      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          reports = response.body.split(
              ","); // Assuming server returns comma-separated report names
        });
      } else {
        throw Exception("Failed to load reports");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _downloadReport(String reportName) async {
    try {
      final response =
          await http.get(Uri.parse("$downloadReportUrl?report=$reportName"));
      if (response.statusCode == 200) {
        final directory = Directory("/storage/emulated/0/Download");
        if (!directory.existsSync()) {
          directory.createSync(recursive: true);
        }

        final file = File("${directory.path}/$reportName");
        file.writeAsBytesSync(response.bodyBytes);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$reportName downloaded successfully!")));
      } else {
        throw Exception("Failed to download report");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Download Reports"),
      ),
      body: reports.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: reports.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(reports[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () => _downloadReport(reports[index]),
                  ),
                );
              },
            ),
    );
  }
}

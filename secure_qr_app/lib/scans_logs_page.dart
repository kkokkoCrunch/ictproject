import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String apiBase =
    "https://secureqr-api-bdhnbpffhyctejfc.eastasia-01.azurewebsites.net";

class ScanLogsPage extends StatefulWidget {
  final String jwt;

  const ScanLogsPage({super.key, required this.jwt});

  @override
  State<ScanLogsPage> createState() => _ScanLogsPageState();
}

class _ScanLogsPageState extends State<ScanLogsPage> {
  List<dynamic> logs = [];
  bool loading = true;

  Future<void> loadLogs() async {
    final url = Uri.parse("$apiBase/api/scans");

    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer ${widget.jwt}"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        logs = data;
        loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("QR Scan Logs")),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final item = logs[index];

                String result = item["result"] ?? "Unknown";
                bool suspicious = result == "DUPLICATE";

                Color color = Colors.grey;
                IconData icon = Icons.qr_code;

                if (result == "VALID") {
                  color = Colors.green;
                  icon = Icons.check_circle;
                }

                if (result == "DUPLICATE") {
                  color = Colors.orange;
                  icon = Icons.warning;
                }

                if (result == "EXPIRED") {
                  color = Colors.red;
                  icon = Icons.error;
                }

                return ListTile(
                  leading: Icon(icon, color: color),

                  title: Text(
                    result,
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),

                  subtitle: Text(
                    suspicious
                        ? "Possible replay attack • ${item["studentId"] ?? "Unknown"} • ${item["timestamp"] ?? ""}"
                        : "${item["studentId"] ?? "Unknown"} • ${item["timestamp"] ?? ""}",
                  ),
                );
              },
            ),
    );
  }
}

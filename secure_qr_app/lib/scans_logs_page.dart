import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

class ScanLogsPage extends StatefulWidget {
  final String jwt;
  final String sessionId;

  const ScanLogsPage({super.key, required this.jwt, required this.sessionId});

  @override
  State<ScanLogsPage> createState() => _ScanLogsPageState();
}

class _ScanLogsPageState extends State<ScanLogsPage> {
  List<dynamic> logs = [];
  bool loading = true;

  Future<void> loadLogs() async {
    try {
      final url = Uri.parse("$apiBase/api/sessions/${widget.sessionId}/scans");

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
      } else {
        print("Scan logs API error: ${response.statusCode}");

        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      print("Scan logs exception: $e");

      setState(() {
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
          : logs.isEmpty
          ? const Center(
              child: Text(
                "No scans yet",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            )
          : ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final item = logs[index];

                String result = item["result"] ?? "Unknown";
                bool suspicious =
                    result == "DUPLICATE" ||
                    result == "CHECKIN_DUP" ||
                    result == "INVALID_SIGNATURE" ||
                    result == "CHECKIN_INVALID_SIGNATURE";

                Color color = Colors.grey;
                IconData icon = Icons.qr_code;

                if (result == "VALID" || result == "CHECKIN_OK") {
                  color = Colors.green;
                  icon = Icons.check_circle;
                }

                if (result == "DUPLICATE" || result == "CHECKIN_DUP") {
                  color = Colors.orange;
                  icon = Icons.warning;
                }

                if (result == "EXPIRED" || result == "CHECKIN_EXPIRED") {
                  color = Colors.red;
                  icon = Icons.error;
                }

                if (result == "INVALID_SIGNATURE" ||
                    result == "CHECKIN_INVALID_SIGNATURE" ||
                    result == "UNKNOWN" ||
                    result == "CHECKIN_UNKNOWN") {
                  color = Colors.red;
                  icon = Icons.cancel;
                }

                return ListTile(
                  leading: Icon(icon, color: color),
                  title: Text(
                    result,
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                  subtitle: Text(
                    suspicious
                        ? "Possible suspicious scan • ${item["studentId"] ?? "Unknown"} • ${item["scannedAtUtc"] ?? item["timestamp"] ?? ""}"
                        : "${item["studentId"] ?? "Unknown"} • ${item["scannedAtUtc"] ?? item["timestamp"] ?? ""}",
                  ),
                );
              },
            ),
    );
  }
}

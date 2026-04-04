import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

/*const String apiBase =
    "https://secureqr-api-bdhnbpffhyctejfc.eastasia-01.azurewebsites.net";*/

class AdminIncidentsPage extends StatefulWidget {
  final String jwt;

  const AdminIncidentsPage({super.key, required this.jwt});

  @override
  State<AdminIncidentsPage> createState() => _AdminIncidentsPageState();
}

class _AdminIncidentsPageState extends State<AdminIncidentsPage> {
  List<dynamic> incidents = [];
  bool loading = true;

  Future<void> loadIncidents() async {
    final response = await http.get(
      Uri.parse("$apiBase/api/security/incidents"),
      headers: {"Authorization": "Bearer ${widget.jwt}"},
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      setState(() {
        incidents = jsonDecode(response.body);
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to load incidents")));
    }
  }

  @override
  void initState() {
    super.initState();
    loadIncidents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Security Incidents")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : incidents.isEmpty
          ? const Center(
              child: Text(
                "No security incidents yet",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            )
          : ListView.builder(
              itemCount: incidents.length,
              itemBuilder: (context, index) {
                final item = incidents[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                    ),
                    title: Text(
                      item["reason"] ?? "Unknown Reason",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Token: ${item["token"] ?? "Unknown"}\n"
                      "Session: ${item["sessionId"] ?? "Unknown"}\n"
                      "Reported At: ${item["reportedAtUtc"] ?? ""}",
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}

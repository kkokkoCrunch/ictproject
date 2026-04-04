import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

class AttendancePage extends StatefulWidget {
  final String jwt;
  final String sessionId;

  const AttendancePage({super.key, required this.jwt, required this.sessionId});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  List attendance = [];

  Future<void> loadAttendance() async {
    final response = await http.get(
      Uri.parse("$apiBase/api/sessions/${widget.sessionId}/attendance"),
      headers: {"Authorization": "Bearer ${widget.jwt}"},
    );

    if (response.statusCode == 200) {
      setState(() {
        attendance = jsonDecode(response.body);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadAttendance();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Attendance List")),
      body: attendance.isEmpty
          ? const Center(
              child: Text(
                "No attendance records yet",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            )
          : ListView.builder(
              itemCount: attendance.length,
              itemBuilder: (context, index) {
                final item = attendance[index];

                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(item["studentId"] ?? "Unknown"),
                  subtitle: Text(item["checkedInAtUtc"] ?? ""),
                );
              },
            ),
    );
  }
}

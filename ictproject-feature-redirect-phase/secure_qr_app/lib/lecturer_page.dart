import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';

import 'attendance_page.dart';
import 'scans_logs_page.dart';
import 'login_page.dart';
import 'config.dart';

const String apiBase =
    "https://secureqr-api-bdhnbpffhyctejfc.eastasia-01.azurewebsites.net";

class LecturerPage extends StatefulWidget {
  final String jwt;

  const LecturerPage({super.key, required this.jwt});

  @override
  State<LecturerPage> createState() => _LecturerPageState();
}

class _LecturerPageState extends State<LecturerPage> {
  final nameController = TextEditingController();

  String? sessionId;
  String? qrUrl;

  int attendanceCount = 0;
  List<dynamic> attendanceList = [];

  Timer? qrTimer;
  Timer? countdownTimer;
  Timer? attendanceTimer;

  int countdown = 30;

  Future<void> loadAttendanceCount() async {
    if (sessionId == null) return;

    final response = await http.get(
      Uri.parse("$apiBase/api/sessions/$sessionId/attendance"),
      headers: {"Authorization": "Bearer ${widget.jwt}"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        attendanceList = data;
        attendanceCount = data.length;
      });
    }
  }

  Future<void> createSession() async {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a session name")),
      );
      return;
    }

    final response = await http.post(
      Uri.parse("$apiBase/api/sessions"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${widget.jwt}",
      },
      body: jsonEncode({
        "name": nameController.text,
        "validFromUtc": DateTime.now().toUtc().toIso8601String(),
        "validToUtc": DateTime.now()
            .toUtc()
            .add(const Duration(hours: 2))
            .toIso8601String(),
        "rotationSeconds": 30,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        sessionId = data["sessionId"];
      });

      await rotateQR();
      startRotation();
    }
  }

  Future<void> rotateQR() async {
    if (sessionId == null) return;

    final response = await http.post(
      Uri.parse("$apiBase/api/sessions/$sessionId/rotate"),
      headers: {"Authorization": "Bearer ${widget.jwt}"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        qrUrl = data["qrUrl"];
        countdown = 30;
      });
    }
  }

  void startRotation() {
    qrTimer?.cancel();
    countdownTimer?.cancel();
    attendanceTimer?.cancel();

    qrTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      rotateQR();
    });

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        countdown--;
        if (countdown <= 0) countdown = 30;
      });
    });

    attendanceTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      loadAttendanceCount();
    });
  }

  @override
  void dispose() {
    qrTimer?.cancel();
    countdownTimer?.cancel();
    attendanceTimer?.cancel();
    super.dispose();
  }

  Widget dashboardButton(String title, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: Card(
        elevation: 4,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 120,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40),

                const SizedBox(height: 10),

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lecturer Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.dashboard, size: 40, color: Colors.blue),

                    const SizedBox(width: 16),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Welcome, Lecturer",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          sessionId == null
                              ? "No active session"
                              : "Active Session Running",
                        ),

                        const SizedBox(height: 4),

                        Text(
                          "Students Checked In: $attendanceCount",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Session Name"),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: createSession,
                child: const Text("Create Session"),
              ),
            ),

            const SizedBox(height: 30),

            if (qrUrl != null) ...[
              QrImageView(data: qrUrl!, size: 220),

              const SizedBox(height: 10),

              Text(
                "QR refresh in $countdown seconds",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],

            const SizedBox(height: 20),

            if (attendanceList.isNotEmpty) ...[
              const Text(
                "Students Checked In",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: attendanceList.length,
                  itemBuilder: (context, index) {
                    final item = attendanceList[index];

                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(item["studentId"] ?? "Unknown"),
                      subtitle: Text(item["checkedInAtUtc"] ?? ""),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 30),

            Row(
              children: [
                dashboardButton("View Attendance", Icons.people, () {
                  if (sessionId == null) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AttendancePage(
                        jwt: widget.jwt,
                        sessionId: sessionId!,
                      ),
                    ),
                  );
                }),

                const SizedBox(width: 10),

                dashboardButton("Scan Logs", Icons.qr_code, () {
                  if (sessionId == null) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ScanLogsPage(jwt: widget.jwt, sessionId: sessionId!),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

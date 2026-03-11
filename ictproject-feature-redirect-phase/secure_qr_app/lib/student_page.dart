import 'package:flutter/material.dart';
import 'scanner_page.dart';

class StudentPage extends StatelessWidget {
  final String jwt;

  const StudentPage({super.key, required this.jwt});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Dashboard")),

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
                    const Icon(Icons.school, size: 40, color: Colors.blue),

                    const SizedBox(width: 16),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Welcome, Student",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 4),

                        Text("Ready to scan attendance QR"),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 60,

              child: ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_scanner),

                label: const Text(
                  "Scan Attendance QR",
                  style: TextStyle(fontSize: 18),
                ),

                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ScannerPage(jwt: jwt)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

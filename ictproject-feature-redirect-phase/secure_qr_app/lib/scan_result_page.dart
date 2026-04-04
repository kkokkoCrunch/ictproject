import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

const String apiBase =
    "https://secureqr-api-bdhnbpffhyctejfc.eastasia-01.azurewebsites.net";

class ScanResultPage extends StatelessWidget {
  final String jwt;
  final String token;
  final String result;
  final String message;

  const ScanResultPage({
    super.key,
    required this.jwt,
    required this.token,
    required this.result,
    required this.message,
  });

  Future<void> reportQr(BuildContext context) async {
    try {
      final response = await http.post(
        Uri.parse("$apiBase/api/security/report"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $jwt",
        },
        body: jsonEncode({"token": token, "reason": "STUDENT_REPORT_$result"}),
      );

      if (!context.mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("QR reported successfully")),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to report QR")));
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to report QR")));
    }
  }

  IconData getResultIcon() {
    switch (result) {
      case "CHECKED_IN":
        return Icons.check_circle;
      case "DUPLICATE":
        return Icons.warning_amber_rounded;
      case "EXPIRED":
        return Icons.access_time_filled;
      case "OUTSIDE_LOCATION":
        return Icons.location_off;
      case "INVALID_QR":
        return Icons.cancel;
      case "OUTSIDE_WINDOW":
        return Icons.event_busy;
      default:
        return Icons.help;
    }
  }

  Color getResultColor() {
    switch (result) {
      case "CHECKED_IN":
        return Colors.green;
      case "DUPLICATE":
        return Colors.orange;
      case "EXPIRED":
        return Colors.red;
      case "OUTSIDE_LOCATION":
        return Colors.red;
      case "INVALID_QR":
        return Colors.red;
      case "OUTSIDE_WINDOW":
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  String getResultTitle() {
    switch (result) {
      case "CHECKED_IN":
        return "Valid QR";
      case "DUPLICATE":
        return "Duplicate Check-In";
      case "EXPIRED":
        return "Expired QR";
      case "OUTSIDE_LOCATION":
        return "Outside Allowed Location";
      case "INVALID_QR":
        return "Invalid QR";
      case "OUTSIDE_WINDOW":
        return "Outside Attendance Window";
      default:
        return "Unknown Result";
    }
  }

  bool canReport() {
    return result != "CHECKED_IN";
  }

  @override
  Widget build(BuildContext context) {
    final color = getResultColor();

    return Scaffold(
      appBar: AppBar(title: const Text("Scan Result")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(getResultIcon(), size: 72, color: color),
                  const SizedBox(height: 16),
                  Text(
                    getResultTitle(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (canReport()) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => reportQr(context),
                        icon: const Icon(Icons.report_problem),
                        label: const Text("Report Suspicious QR"),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text("Scan Again"),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("Back"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

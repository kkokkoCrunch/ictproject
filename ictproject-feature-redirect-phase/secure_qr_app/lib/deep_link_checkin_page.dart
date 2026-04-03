import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'scan_result_page.dart';

const String apiBase =
    "https://secureqr-api-bdhnbpffhyctejfc.eastasia-01.azurewebsites.net";

class DeepLinkCheckInPage extends StatefulWidget {
  final String jwt;
  final String token;
  final String? sig;

  const DeepLinkCheckInPage({
    super.key,
    required this.jwt,
    required this.token,
    required this.sig,
  });

  @override
  State<DeepLinkCheckInPage> createState() => _DeepLinkCheckInPageState();
}

class _DeepLinkCheckInPageState extends State<DeepLinkCheckInPage> {
  bool loading = true;
  String statusText = "Processing secure check-in...";

  @override
  void initState() {
    super.initState();
    processCheckIn();
  }

  Future<void> processCheckIn() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ScanResultPage(
              jwt: widget.jwt,
              token: widget.token,
              result: "LOCATION_REQUIRED",
              message: "Location permission is required to check in.",
            ),
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final response = await http.post(
        Uri.parse("$apiBase/api/attendance/checkin"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.jwt}",
        },
        body: jsonEncode({
          "token": widget.token,
          "sig": widget.sig,
          "latitude": position.latitude,
          "longitude": position.longitude,
        }),
      );

      final data = jsonDecode(response.body);

      String message;

      switch (data["result"]) {
        case "CHECKED_IN":
          message = "🟢 Attendance Recorded";
          break;
        case "DUPLICATE":
          message = "🟡 Already Checked In";
          break;
        case "EXPIRED":
          message = "🔴 QR Expired";
          break;
        case "OUTSIDE_LOCATION":
          message = "📍 You are outside the classroom";
          break;
        case "OUTSIDE_WINDOW":
          message = "⏰ This QR is outside the attendance time window";
          break;
        case "INVALID_QR":
          message = "❌ Invalid QR";
          break;
        case "LOCATION_REQUIRED":
          message = "📍 Location permission is required";
          break;
        default:
          message = "❌ Failed to process QR";
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ScanResultPage(
            jwt: widget.jwt,
            token: widget.token,
            result: data["result"] ?? "UNKNOWN",
            message: message,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ScanResultPage(
            jwt: widget.jwt,
            token: widget.token,
            result: "UNKNOWN",
            message: "❌ Failed to process QR",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Secure Check-In")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading) const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

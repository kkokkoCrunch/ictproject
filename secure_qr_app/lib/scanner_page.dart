import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:geolocator/geolocator.dart';

const String apiBase =
    "https://secureqr-api-bdhnbpffhyctejfc.eastasia-01.azurewebsites.net";

class ScannerPage extends StatefulWidget {
  final String jwt;

  const ScannerPage({super.key, required this.jwt});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  bool scanned = false;

  late AnimationController scanController;
  late Animation<double> scanAnimation;

  @override
  void initState() {
    super.initState();

    scanController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    scanAnimation = Tween<double>(begin: 0, end: 250).animate(scanController);
  }

  void onQRViewCreated(QRViewController controller) {
    this.controller = controller;

    controller.scannedDataStream.listen((scanData) {
      if (scanned) return;
      scanned = true;

      final code = scanData.code;
      if (code == null) return;

      Uri uri = Uri.parse(code);

      String token = uri.pathSegments.last;
      String? sig = uri.queryParameters["sig"];

      controller.pauseCamera();

      checkIn(token, sig);
    });
  }

  Future<void> checkIn(String token, String? sig) async {
    final url = Uri.parse("$apiBase/api/attendance/checkin");

    try {
      // Request location permission first
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission required")),
        );
        return;
      }

      // Get GPS location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.jwt}",
        },
        body: jsonEncode({
          "token": token,
          "latitude": position.latitude,
          "longitude": position.longitude,
        }),
      );

      final data = jsonDecode(response.body);

      String message;
      Color color;

      switch (data["result"]) {
        case "CHECKED_IN":
          message = "🟢 Attendance Recorded";
          color = Colors.green;
          break;

        case "DUPLICATE":
          message = "🟡 Already Checked In";
          color = Colors.orange;
          break;

        case "EXPIRED":
          message = "🔴 QR Expired";
          color = Colors.red;
          break;

        case "OUTSIDE_LOCATION":
          message = "📍 You are outside the classroom";
          color = Colors.red;
          break;

        default:
          message = "❌ Invalid QR";
          color = Colors.red;
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Attendance Status"),
          content: Text(message, style: TextStyle(fontSize: 18, color: color)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                scanned = false;
                controller?.resumeCamera();
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double scanBoxSize = 250;

    return Scaffold(
      appBar: AppBar(title: const Text("Secure QR Scanner")),

      body: Stack(
        children: [
          QRView(key: qrKey, onQRViewCreated: onQRViewCreated),

          Container(color: Colors.black.withOpacity(0.5)),

          AnimatedBuilder(
            animation: scanAnimation,
            builder: (context, child) {
              return Positioned(
                top:
                    MediaQuery.of(context).size.height / 2 -
                    scanBoxSize / 2 +
                    scanAnimation.value,
                left: MediaQuery.of(context).size.width / 2 - scanBoxSize / 2,
                child: Container(
                  width: scanBoxSize,
                  height: 2,
                  color: Colors.redAccent,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    scanController.dispose();
    controller?.dispose();
    super.dispose();
  }
}

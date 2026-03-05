import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

void main() {
  runApp(const MyApp());
}

const String apiBase =
    "https://secureqr-api-bdhnbpffhyctejfc.eastasia-01.azurewebsites.net";

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: LoginPage());
  }
}

/// --------------------
/// LOGIN PAGE
/// --------------------
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _studentIdCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);

    final url = Uri.parse("$apiBase/api/auth/login");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "studentId": _studentIdCtrl.text.trim(),
          "password": _passwordCtrl.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ✅ Change this key if your backend returns token under a different name
        final String? jwt = data["accessToken"] as String?;

        if (jwt == null || jwt.isEmpty) {
          _showError("Login response missing accessToken.");
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ScannerPage(jwt: jwt)),
        );
      } else {
        _showError("Login failed (${response.statusCode}).");
      }
    } catch (e) {
      if (!mounted) return;
      _showError("Login error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _studentIdCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _studentIdCtrl,
              decoration: const InputDecoration(labelText: "Student ID"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                child: Text(_loading ? "Logging in..." : "Login"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// --------------------
/// SCANNER PAGE
/// --------------------
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

      controller.pauseCamera();
      checkIn(token);
    });
  }

  Future<void> checkIn(String token) async {
    final url = Uri.parse("$apiBase/api/attendance/checkin");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.jwt}",
        },
        body: jsonEncode({"token": token}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        String message = "";
        Color color = Colors.green;

        switch (data["result"]) {
          case "VALID":
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

          case "OUTSIDE_WINDOW":
            message = "🚫 Attendance Closed";
            color = Colors.red;
            break;

          case "INVALID":
          default:
            message = "❌ Invalid QR Code";
            color = Colors.red;
            break;
        }

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Attendance Status"),
            content: Text(
              message,
              style: TextStyle(fontSize: 18, color: color),
            ),
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
      } else {
        _showError("Check-in failed (${response.statusCode}).");
      }
    } catch (e) {
      _showError("Check-in error: $e");
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(msg),
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
  }

  @override
  Widget build(BuildContext context) {
    const double scanBoxSize = 250;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Secure QR Scanner"),
        actions: [
          IconButton(
            tooltip: "Logout",
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          QRView(key: qrKey, onQRViewCreated: onQRViewCreated),

          // Dim overlay
          Container(color: Colors.black.withOpacity(0.5)),

          // Animated scan line
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

          // Corner brackets
          Center(
            child: SizedBox(
              width: scanBoxSize,
              height: scanBoxSize,
              child: Stack(
                children: [
                  Positioned(top: 0, left: 0, child: buildCorner()),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Transform.rotate(angle: 1.57, child: buildCorner()),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Transform.rotate(angle: -1.57, child: buildCorner()),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Transform.rotate(angle: 3.14, child: buildCorner()),
                  ),
                ],
              ),
            ),
          ),

          // Text
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 80),
              child: const Text(
                "Scan the attendance QR code",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCorner() {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.green, width: 4),
          left: BorderSide(color: Colors.green, width: 4),
        ),
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

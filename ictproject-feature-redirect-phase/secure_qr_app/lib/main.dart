import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:uni_links/uni_links.dart';

void main() {
  runApp(const SecureQrApp());
}

class SecureQrApp extends StatefulWidget {
  const SecureQrApp({super.key});

  @override
  State<SecureQrApp> createState() => _SecureQrAppState();
}

class _SecureQrAppState extends State<SecureQrApp> {
  @override
  void initState() {
    super.initState();
    initDeepLink();
  }

  void initDeepLink() async {
    try {
      final uri = await getInitialUri();

      if (uri != null) {
        final token = uri.queryParameters['token'];

        if (token != null) {
          print("Token received: $token");
        }
      }
    } catch (e) {
      print("Deep link error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Secure QR Attendance",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginPage(),
    );
  }
}

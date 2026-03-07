import 'package:flutter/material.dart';
import 'login_page.dart';

void main() {
  runApp(const SecureQrApp());
}

class SecureQrApp extends StatelessWidget {
  const SecureQrApp({super.key});

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

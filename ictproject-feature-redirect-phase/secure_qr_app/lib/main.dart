import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

import 'login_page.dart';

void main() {
  runApp(const SecureQrApp());
}

class SecureQrApp extends StatefulWidget {
  const SecureQrApp({super.key});

  @override
  State<SecureQrApp> createState() => _SecureQrAppState();
}

class _SecureQrAppState extends State<SecureQrApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();

    _appLinks = AppLinks();

    _linkSub = _appLinks.uriLinkStream.listen((uri) {
      if (uri != null) {
        final token = uri.queryParameters['token'];

        if (token != null) {
          print("Token received: $token");
        }
      }
    });
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
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

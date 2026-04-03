import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

import 'login_page.dart';
import 'student_page.dart';
import 'deep_link_checkin_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

  String? currentJwt;

  @override
  void initState() {
    super.initState();

    _appLinks = AppLinks();

    _linkSub = _appLinks.uriLinkStream.listen((uri) {
      final token = uri.queryParameters['token'];
      final sig = uri.queryParameters['sig'];

      if (token != null && currentJwt != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) =>
                DeepLinkCheckInPage(jwt: currentJwt!, token: token, sig: sig),
          ),
        );
      }
    });
  }

  void setJwt(String jwt) {
    currentJwt = jwt;
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: "Secure QR Attendance",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginPage(onLoginSuccess: setJwt),
    );
  }
}

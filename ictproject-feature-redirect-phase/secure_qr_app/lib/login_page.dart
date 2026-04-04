import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'student_page.dart';
import 'lecturer_page.dart';
import 'admin_page.dart';
import 'config.dart';

const String apiBase =
    "https://secureqr-api-bdhnbpffhyctejfc.eastasia-01.azurewebsites.net";

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;

  Future<void> login() async {
    setState(() {
      loading = true;
    });

    final response = await http.post(
      Uri.parse("$apiBase/api/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": usernameController.text.trim(),
        "password": passwordController.text.trim(),
      }),
    );

    setState(() {
      loading = false;
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final jwt = data["accessToken"];
      final role = data["role"];

      if (role == "Student") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => StudentPage(jwt: jwt)),
        );
      }

      if (role == "Lecturer") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LecturerPage(jwt: jwt)),
        );
      }

      if (role == "Admin") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AdminPage(jwt: jwt)),
        );
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Login failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SecureQR Login")),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: "Username"),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : login,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text("Login"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

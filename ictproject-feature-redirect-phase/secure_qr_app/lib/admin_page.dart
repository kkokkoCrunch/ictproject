import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'admin_incidents_page.dart';
import 'login_page.dart';

const String apiBase = "https://YOUR-NEW-BACKEND-URL.azurewebsites.net";

class AdminPage extends StatefulWidget {
  final String jwt;

  const AdminPage({super.key, required this.jwt});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final nameController = TextEditingController();

  final newUsernameController = TextEditingController();
  final newPasswordController = TextEditingController();
  String selectedRole = "Student";

  String? qrUrl;
  String? token;
  String? validToUtc;
  bool loading = false;
  bool creatingUser = false;

  Future<void> createStaticQr() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter an event name")),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final response = await http.post(
        Uri.parse("$apiBase/api/admin/static-qr"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.jwt}",
        },
        body: jsonEncode({
          "name": nameController.text.trim(),
          "validFromUtc": DateTime.now().toUtc().toIso8601String(),
          "validToUtc": DateTime.now()
              .toUtc()
              .add(const Duration(days: 30))
              .toIso8601String(),
        }),
      );

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          qrUrl = data["qrUrl"];
          token = data["token"];
          validToUtc = data["validToUtc"];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Static QR created successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to create static QR: ${response.body}"),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error creating static QR")));
    }
  }

  Future<void> createUser() async {
    if (newUsernameController.text.trim().isEmpty ||
        newPasswordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in username and password")),
      );
      return;
    }

    setState(() {
      creatingUser = true;
    });

    try {
      final response = await http.post(
        Uri.parse("$apiBase/api/auth/register"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.jwt}",
        },
        body: jsonEncode({
          "username": newUsernameController.text.trim(),
          "password": newPasswordController.text.trim(),
          "role": selectedRole,
        }),
      );

      if (!mounted) return;

      setState(() {
        creatingUser = false;
      });

      if (response.statusCode == 200) {
        newUsernameController.clear();
        newPasswordController.clear();

        setState(() {
          selectedRole = "Student";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User created successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to create user: ${response.body}")),
        );
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        creatingUser = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error creating user")));
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    newUsernameController.dispose();
    newPasswordController.dispose();
    super.dispose();
  }

  Widget buildCreateUserCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Create New User",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newUsernameController,
              decoration: const InputDecoration(
                labelText: "Username",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: const InputDecoration(
                labelText: "Role",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "Student", child: Text("Student")),
                DropdownMenuItem(value: "Lecturer", child: Text("Lecturer")),
                DropdownMenuItem(value: "Admin", child: Text("Admin")),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedRole = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: creatingUser ? null : createUser,
                child: creatingUser
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Create User"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStaticQrCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Create Event Static QR",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Event Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : createStaticQr,
                child: loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Generate Static QR"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildQrResultCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Generated Event QR",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            QrImageView(data: qrUrl!, size: 220),
            const SizedBox(height: 16),
            const Text(
              "QR Link:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            SelectableText(qrUrl!, textAlign: TextAlign.center),
            if (token != null) ...[
              const SizedBox(height: 16),
              const Text(
                "Token:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              SelectableText(token!, textAlign: TextAlign.center),
            ],
            if (validToUtc != null) ...[
              const SizedBox(height: 16),
              const Text(
                "Valid Until (UTC):",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              SelectableText(validToUtc!, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildCreateUserCard(),
            const SizedBox(height: 24),
            buildStaticQrCard(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminIncidentsPage(jwt: widget.jwt),
                    ),
                  );
                },
                icon: const Icon(Icons.security),
                label: const Text("View Security Incidents"),
              ),
            ),
            const SizedBox(height: 24),
            if (qrUrl != null) buildQrResultCard(),
          ],
        ),
      ),
    );
  }
}

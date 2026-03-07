import 'package:flutter/material.dart';

class AdminPage extends StatelessWidget {
  final String jwt;

  const AdminPage({super.key, required this.jwt});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard")),
      body: const Center(child: Text("Admin panel coming soon")),
    );
  }
}

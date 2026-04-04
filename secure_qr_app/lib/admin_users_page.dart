import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

class AdminUsersPage extends StatefulWidget {
  final String jwt;

  const AdminUsersPage({super.key, required this.jwt});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  List<dynamic> users = [];
  bool loading = true;

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  String selectedRole = "Student";

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    final response = await http.get(
      Uri.parse("$apiBase/api/auth/users"),
      headers: {"Authorization": "Bearer ${widget.jwt}"},
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      setState(() {
        users = jsonDecode(response.body);
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to load users")));
    }
  }

  Future<void> addUser() async {
    final response = await http.post(
      Uri.parse("$apiBase/api/auth/register"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${widget.jwt}",
      },
      body: jsonEncode({
        "username": usernameController.text.trim(),
        "password": passwordController.text.trim(),
        "role": selectedRole,
      }),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      usernameController.clear();
      passwordController.clear();

      await loadUsers();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User added")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add user: ${response.body}")),
      );
    }
  }

  Future<void> deleteUser(String username) async {
    final response = await http.delete(
      Uri.parse("$apiBase/api/auth/users/$username"),
      headers: {"Authorization": "Bearer ${widget.jwt}"},
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      await loadUsers();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User deleted")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete user: ${response.body}")),
      );
    }
  }

  Future<void> showEditDialog(dynamic user) async {
    final passwordEditController = TextEditingController();
    String role = user["role"];

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Edit ${user["username"]}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: role,
              items: const [
                DropdownMenuItem(value: "Student", child: Text("Student")),
                DropdownMenuItem(value: "Lecturer", child: Text("Lecturer")),
                DropdownMenuItem(value: "Admin", child: Text("Admin")),
              ],
              onChanged: (value) {
                role = value!;
              },
              decoration: const InputDecoration(labelText: "Role"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordEditController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "New Password (leave blank to keep same)",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final response = await http.put(
                Uri.parse("$apiBase/api/auth/users/${user["username"]}"),
                headers: {
                  "Content-Type": "application/json",
                  "Authorization": "Bearer ${widget.jwt}",
                },
                body: jsonEncode({
                  "password": passwordEditController.text.trim(),
                  "role": role,
                }),
              );

              if (!mounted) return;

              Navigator.pop(context);

              if (response.statusCode == 200) {
                await loadUsers();

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("User updated")));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Failed to update user: ${response.body}"),
                  ),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Users")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextField(
                            controller: usernameController,
                            decoration: const InputDecoration(
                              labelText: "Username",
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: "Password",
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: selectedRole,
                            items: const [
                              DropdownMenuItem(
                                value: "Student",
                                child: Text("Student"),
                              ),
                              DropdownMenuItem(
                                value: "Lecturer",
                                child: Text("Lecturer"),
                              ),
                              DropdownMenuItem(
                                value: "Admin",
                                child: Text("Admin"),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedRole = value!;
                              });
                            },
                            decoration: const InputDecoration(
                              labelText: "Role",
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: addUser,
                              child: const Text("Add User"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];

                        return Card(
                          child: ListTile(
                            title: Text(user["username"]),
                            subtitle: Text("Role: ${user["role"]}"),
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => showEditDialog(user),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => deleteUser(user["username"]),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import './widgets/sidebar_widget.dart';

class SettingsScreen extends StatefulWidget {
  final Map<String, dynamic>? user;

  const SettingsScreen({super.key, this.user});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  String message = "";

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      usernameController.text = widget.user!['username'] ?? '';
      emailController.text = widget.user!['email'] ?? '';
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      isLoading = true;
      message = "";
    });

    try {
      Map<String, dynamic> result = await AuthService.updateProfile(
        usernameController.text,
        emailController.text,
        passwordController.text.isEmpty ? null : passwordController.text
      );

      setState(() {
        message = result["message"];
        if (result["success"]) {
          passwordController.clear();
        }
      });
    } catch (e) {
      setState(() {
        message = "Error updating profile: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("Are you sure you want to delete your account? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        isLoading = true;
        message = "";
      });

      try {
        Map<String, dynamic> result = await AuthService.deleteAccount();
        
        if (result["success"]) {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        } else {
          setState(() {
            message = result["message"];
            isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          message = "Error deleting account: $e";
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Account Settings"),
        backgroundColor: Colors.blueAccent,
      ),
      drawer: SidebarWidget(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Row(
            children: [
              // Left side: Form area
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Profile Settings", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    // Username Field with updated style
                    const Text("Username", style: TextStyle(fontSize: 16)),
                    TextField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        hintText: "Enter your username",
                        filled: true,
                        fillColor: Colors.blueGrey[50] ?? Colors.purple,
                        labelStyle: const TextStyle(fontSize: 12),
                        contentPadding: const EdgeInsets.only(left: 30),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueGrey[50] ?? Colors.purple),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueGrey[50] ?? Colors.purple),
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Email Field with updated style
                    const Text("Email", style: TextStyle(fontSize: 16)),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        hintText: "Enter email",
                        filled: true,
                        fillColor: Colors.blueGrey[50] ?? Colors.purple,
                        labelStyle: const TextStyle(fontSize: 12),
                        contentPadding: const EdgeInsets.only(left: 30),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueGrey[50] ?? Colors.purple),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueGrey[50] ?? Colors.purple),
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                    ),
                    const SizedBox(height: 10),

                    // Password Field with updated style
                    const Text("Password", style: TextStyle(fontSize: 16)),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: "New password (leave blank to keep current)",
                        filled: true,
                        fillColor: Colors.purple[50] ?? Colors.purple,
                        labelStyle: const TextStyle(fontSize: 12),
                        contentPadding: const EdgeInsets.only(left: 30),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.purple[50] ?? Colors.purple),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueGrey[50] ?? Colors.purple),
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Message display
                    if (message.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(10),
                        color: message.contains("Error") ? Colors.red[100] : Colors.grey[100],
                        child: Text(message),
                      ),
                    const SizedBox(height: 20),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: isLoading ? null : _updateProfile,
                          style: ElevatedButton.styleFrom(
                             backgroundColor: Colors.purple,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("Update Profile", style: TextStyle(color: Colors.white)),
                        ),
                        ElevatedButton(
                          onPressed: isLoading ? null : _deleteAccount,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: const Text("Delete Account", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                    const Divider(),
                    const SizedBox(height: 10),

                    // App Settings Section
                    const Text("App Settings", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    SwitchListTile(
                      title: const Text("Dark Mode"),
                      value: isDarkMode,
                      onChanged: (value) {
                        setState(() {
                          isDarkMode = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Right side: Image area
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Image.asset(
                    'assets/account.png', // Replace with the correct path
                    fit: BoxFit.contain,
                    width: 500,
                    height: 500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

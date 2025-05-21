import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dashboard.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService authService = AuthService();
  bool isLoading = false;
  String errorMessage = "";

  void _register() async {
    if (emailController.text.isEmpty || 
        usernameController.text.isEmpty || 
        passwordController.text.isEmpty) {
      setState(() {
        errorMessage = "All fields are required";
      });
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(emailController.text)) {
      setState(() {
        errorMessage = "Please enter a valid email address";
      });
      return;
    }

    if (passwordController.text.length < 6) {
      setState(() {
        errorMessage = "Password must be at least 6 characters long";
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      var response = await authService.registerUser(
        emailController.text,
        usernameController.text,
        passwordController.text,
      );

      if (response["success"] == true) {
        emailController.clear();
        usernameController.clear();
        passwordController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response["message"] ?? "Registration successful!")),
        );

        if (mounted) {
          Future.delayed(Duration(milliseconds: 300), () {
            Navigator.pushReplacementNamed(context, '/login');
          });
        }
      } else {
        setState(() {
          errorMessage = response["message"] ?? "Registration failed";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFf5f5f5),
      appBar: AppBar(
        title: Text("Register"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left side: Image area
              Expanded(
                flex: 1,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Image.asset(
                    'assets/illustration-22.png',  // Ensure correct image path
                    fit: BoxFit.contain,
                    width: 250,  // Resize image width
                    height: 250,  // Resize image height
                  ),
                ),
              ),

              // Right side: Form area
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Sign Up to My Application", style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold)),
                    SizedBox(height: 20),

                    // Email input field
                    Text("Email", style: TextStyle(fontSize: 16)),
                    TextField(
                      controller: emailController, 
                      decoration: InputDecoration(
                        hintText: "Enter email",
                        filled: true,
                        fillColor: Colors.blueGrey[50] ?? Colors.blueGrey,
                        labelStyle: TextStyle(fontSize: 12),
                        contentPadding: EdgeInsets.only(left: 30),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueGrey[50] ?? Colors.blueGrey),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueGrey[50] ?? Colors.blueGrey),
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                    ),
                    SizedBox(height: 16),

                    // Username input field
                    Text("Username", style: TextStyle(fontSize: 16)),
                    TextField(
                      controller: usernameController, 
                      decoration: InputDecoration(
                        hintText: "Enter username",
                        filled: true,
                        fillColor: Colors.blueGrey[50] ?? Colors.blueGrey,
                        labelStyle: TextStyle(fontSize: 12),
                        contentPadding: EdgeInsets.only(left: 30),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueGrey[50] ?? Colors.blueGrey),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueGrey[50] ?? Colors.blueGrey),
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Password input field
                    Text("Password", style: TextStyle(fontSize: 16)),
                    TextField(
                      controller: passwordController, 
                      obscureText: true, 
                      decoration: InputDecoration(
                        hintText: "Enter password",
                        suffixIcon: Icon(Icons.visibility_off_outlined, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.blueGrey[50] ?? Colors.blueGrey,
                        labelStyle: TextStyle(fontSize: 12),
                        contentPadding: EdgeInsets.only(left: 30),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueGrey[50] ?? Colors.blueGrey),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueGrey[50] ?? Colors.blueGrey),
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Error message display
                    if (errorMessage.isNotEmpty)
                      Container(
                        padding: EdgeInsets.all(8),
                        color: Colors.red.shade100,
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(errorMessage, style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 20),

                    // Register button
                    Center(
                      child: isLoading
                          ? CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _register,
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(double.infinity, 50),
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: Text("Register"),
                            ),
                    ),
                    SizedBox(height: 20),

                    // Already have an account link
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: Text("Already have an account? Login", style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

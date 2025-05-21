import 'package:flutter/material.dart';
import '../services/auth_service.dart';  // Import AuthService
import 'dashboard.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService authService = AuthService();
  bool isLoading = false;
  String errorMessage = "";
  bool _obscurePassword = true;  // Add this line for password visibility state

  @override
  void initState() {
    super.initState();
    emailController.clear();
    passwordController.clear();
  }

  void _login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      setState(() {
        errorMessage = "Email and password are required";
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      var response = await authService.loginUser(emailController.text, passwordController.text);

      if (response["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response["message"] ?? "Login successful!")));

        var userData = await AuthService.getCurrentUser();

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => Dashboard(user: userData ?? {})),
            (route) => false,
          );
        }
      } else {
        setState(() {
          errorMessage = response["message"] ?? "Login failed";
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
        title: Text("Login"),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Row(
            children: [
              // Left side: Form area
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Sign In to My Application", style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold)),
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
                    SizedBox(height: 10),

                    // Password input field
                    Text("Password", style: TextStyle(fontSize: 16)),
                    TextFormField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: "Enter password",
                        counterText: 'Forgot password?',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            print('Visibility icon tapped. Current: [32m"+_obscurePassword.toString()+"\u001b[0m');
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
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

                    // Sign In button
                    Center(
                      child: isLoading
                          ? CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(double.infinity, 50),
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: Text("Login"),
                            ),
                    ),
                    SizedBox(height: 20),

                    // Register link
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/register');
                        },
                        child: Text("Don't have an account? Register", style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                      ),
                    ),

                    // Social media login buttons (Google, GitHub, Facebook)
                    SizedBox(height: 20),
                    Center(
                      child: Text("Or continue with", style: TextStyle(color: Colors.black54)),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _socialButton(image: 'assets/google.png'),
                        SizedBox(width: 10),
                        _socialButton(image: 'assets/github.png'),
                        SizedBox(width: 10),
                        _socialButton(image: 'assets/facebook.png'),
                      ],
                    ),
                  ],
                ),
              ),

              // Right side: Image area
              Expanded(
                flex: 1,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: AspectRatio(
                    aspectRatio: 1,  // Maintain aspect ratio
                    child: Image.asset(
                      'assets/illustration-1.png', 
                      fit: BoxFit.contain,  // Ensure it scales without distortion
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialButton({required String image}) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Center(
        child: Image.asset(image, width: 35),
      ),
    );
  }
}


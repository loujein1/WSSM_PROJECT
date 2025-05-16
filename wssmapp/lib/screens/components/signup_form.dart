// components/signup_form.dart

import 'package:flutter/material.dart';
import 'package:wssmapp/constants.dart';
import '../../services/api_service.dart';
import '../login_screen.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  _SignUpFormState createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ApiService apiService = ApiService();

  void _signup() async {
    if (!_formKey.currentState!.validate()) return;

    String email = emailController.text.trim();
    String username = usernameController.text.trim();
    String password = passwordController.text.trim();

    print("🚀 Sending Signup Request...");
    var response = await apiService.signup(email, username, password);

    if (response.containsKey("error")) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Signup failed: ${response['error']}")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Signup successful! Please log in.")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Account',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
          SizedBox(height: 20),

          // Email
          TextFormField(
            controller: emailController,
            decoration: InputDecoration(
              hintText: "Your Email",
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: defaultPadding),
                child: Icon(Icons.email, color: kPrimaryColor),
              ),
              filled: true,
              fillColor: kPrimaryLightColor,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(inputBorderRadius),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(inputBorderRadius),
                borderSide: const BorderSide(color: kPrimaryColor),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          SizedBox(height: 16),

          // Username
          TextFormField(
            controller: usernameController,
            decoration: InputDecoration(
              hintText: "Your Username",
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: defaultPadding),
                child: Icon(Icons.person, color: kPrimaryColor),
              ),
              filled: true,
              fillColor: kPrimaryLightColor,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(inputBorderRadius),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(inputBorderRadius),
                borderSide: const BorderSide(color: kPrimaryColor),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Username is required';
              }
              return null;
            },
          ),
          SizedBox(height: 16),

          // Password
          TextFormField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: "Your Password",
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: defaultPadding),
                child: Icon(Icons.password, color: kPrimaryColor),
              ),
              filled: true,
              fillColor: kPrimaryLightColor,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(inputBorderRadius),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(inputBorderRadius),
                borderSide: const BorderSide(color: kPrimaryColor),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              } else if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          SizedBox(height: 20),

          // Button
          ElevatedButton(
            onPressed: _signup,
            style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: defaultPadding * 1.5, vertical: defaultPadding),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(buttonBorderRadius),
                    ),
                    minimumSize: const Size(double.infinity, 54),
                    elevation: 8,
                    // ignore: deprecated_member_use
                    shadowColor: kPrimaryColor.withOpacity(0.5),
                  ),
                  child: Text(
                    "Create Account".toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
          const SizedBox(height: defaultPadding),

          // Login link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Already have an account? "),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: Text(
                  "Login",
                  style: TextStyle(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

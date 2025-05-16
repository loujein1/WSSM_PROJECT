import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants.dart';
import '../../services/api_service.dart';
import '../dashboard_screen.dart';
import '../signup_screen.dart';
import '../../components/already_have_an_account_check.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ApiService apiService = ApiService();
  bool isLoading = false;

  void _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    var response = await apiService.login(email, password);

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (response["success"] == true && response.containsKey("token")) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', response['id']);
      await prefs.setString('token', response['token']);
      await prefs.setString('email', response['email'] ?? "No email");
      await prefs.setString('username', response['username'] ?? "No username");

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => DashboardScreen()),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: ${response['error']}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            cursorColor: kPrimaryColor,
            decoration: InputDecoration(
              hintText: "Your Email",
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
                return "Email is required";
              } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return "Enter a valid email";
              }
              return null;
            },
          ),
          const SizedBox(height: defaultPadding),
          TextFormField(
            controller: passwordController,
            textInputAction: TextInputAction.done,
            obscureText: true,
            cursorColor: kPrimaryColor,
            decoration: InputDecoration(
              hintText: "Password",
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: defaultPadding),
                child: Icon(Icons.lock, color: kPrimaryColor),
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
                return "Password is required";
              }
              return null;
            },
          ),
          const SizedBox(height: defaultPadding * 1.5),
          isLoading
              ? const CircularProgressIndicator(color: kPrimaryColor)
              : ElevatedButton(
                  onPressed: _login,
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
                    "LOGIN".toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
          const SizedBox(height: defaultPadding),
          AlreadyHaveAnAccountCheck(
            press: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SignUpScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
} 
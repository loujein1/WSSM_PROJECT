import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../constants.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../responsive.dart';
import 'components/background_decoration.dart';
import 'login_screen.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  _UpdateProfileScreenState createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://0397-102-159-238-171.ngrok-free.app'));

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      emailController.text = prefs.getString('email') ?? '';
      usernameController.text = prefs.getString('username') ?? '';
    });
  }

Future<bool> _saveUpdatedData() async {
  String email = emailController.text.trim();
  String username = usernameController.text.trim();

  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('userId') ?? '';
    print("User ID: $userId");

    final response = await _dio.patch(
      '/users/$userId',
      data: {
        'email': email,
        'username': username,
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Profile updated successfully!")),
      );

      await prefs.setString('email', email);
      await prefs.setString('username', username);

      return true; // Return success
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Error updating profile")),
      );
      return false;
    }
  } catch (e) {
    print("❌ Error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("❌ Error updating profile")),
    );
    return false;
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const BackgroundDecoration(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Responsive(
                  mobile: const MobileUpdateProfileScreen(),
                  desktop: SizedBox(
                    width: 450,
                    child: _buildUpdateForm(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateForm() {
    return Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/icons/login.svg',
            height: 150,
          ),
          const SizedBox(height: 20),
          TextField(
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
          ),
          const SizedBox(height: 20),
          TextField(
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
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _saveUpdatedData,
            icon: const Icon(
              Icons.save_alt,
              color: Colors.white,
            ),
            label: Text(
              "Save Changes".toUpperCase(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              padding: const EdgeInsets.symmetric(
                horizontal: defaultPadding * 1.5,
                vertical: defaultPadding,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(buttonBorderRadius),
              ),
              minimumSize: const Size(double.infinity, 54),
              elevation: 8,
              shadowColor: kPrimaryColor.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class MobileUpdateProfileScreen extends StatelessWidget {
  const MobileUpdateProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/icons/login.svg',
            height: 150,
          ),
          const SizedBox(height: 20),
          const _UpdateProfileForm(),
        ],
      ),
    );
  }
}

class _UpdateProfileForm extends StatelessWidget {
  const _UpdateProfileForm();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_UpdateProfileScreenState>();
    return Column(
      children: [
        TextField(
          controller: state?.emailController,
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
        ),
        const SizedBox(height: 20),
        TextField(
          controller: state?.usernameController,
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
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: state?._saveUpdatedData,
          icon: const Icon(
            Icons.save_alt,
            color: Colors.white,
          ),
          label: Text(
            "Save Changes".toUpperCase(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            padding: const EdgeInsets.symmetric(
              horizontal: defaultPadding * 1.5,
              vertical: defaultPadding,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonBorderRadius),
            ),
            minimumSize: const Size(double.infinity, 54),
            elevation: 8,
            shadowColor: kPrimaryColor.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}
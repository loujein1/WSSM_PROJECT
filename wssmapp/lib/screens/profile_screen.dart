import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../responsive.dart';
import 'login_screen.dart';
import 'components/background_decoration.dart';
import '../../constants.dart';
import 'update_profile_screen.dart';
import 'package:dio/dio.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://0397-102-159-238-171.ngrok-free.app'));

  String email = "Loading...";
  String username = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      email = prefs.getString('email') ?? "No email found";
      username = prefs.getString('username') ?? "No username found";
    });
  }

  void _navigateToUpdateProfile() {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const UpdateProfileScreen()),
  ).then((_) => _loadUserData()); // This will reload data when returning
}

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Account"),
          content: const Text("Are you sure you want to delete your account? This action cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteAccount();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              child: const Text("DELETE"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('userId') ?? '';
    String token = prefs.getString('token') ?? '';

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ User ID not found")));
      return;
    }

    try {
      final response = await _dio.delete(
        '/users/$userId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        await prefs.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Account deleted successfully!")));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Error deleting account")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Error deleting account")));
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
                  mobile: const MobileProfileScreen(),
                  desktop: SizedBox(
                    width: 450,
                    child: _buildProfileContent(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    return Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.account_circle, size: 500, color: kPrimaryColor),
          const SizedBox(height: defaultPadding),
          Text(
            "Username: $username",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            "Email: $email",
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: defaultPadding * 2),
          
          // Update Profile Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _navigateToUpdateProfile,
              icon: const Icon(Icons.edit),
              label: const Text("Update Profile"),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(buttonBorderRadius),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 15),

          // Delete Account Button (changed to grey)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _confirmDeleteAccount,
              icon: const Icon(Icons.delete, color: Colors.white),
              label: const Text("Delete Account"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey, // Changed from red to grey
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(buttonBorderRadius),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
          
          const SizedBox(height: defaultPadding * 2),
        ],
      ),
    );
  }
}

class MobileProfileScreen extends StatelessWidget {
  const MobileProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle, size: 100, color: kPrimaryColor),
            const SizedBox(height: defaultPadding),
            const _UserInfo(),
          ],
        ),
      ),
    );
  }
}

class _UserInfo extends StatelessWidget {
  const _UserInfo();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final prefs = snapshot.data!;
        final email = prefs.getString('email') ?? "No email";
        final username = prefs.getString('username') ?? "No username";

        return Column(
          children: [
            Text("Username: $username", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Email: $email", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 30),
            
            // Mobile version buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UpdateProfileScreen()),
                  ).then((_) {
                    final state = context.findAncestorStateOfType<_ProfileScreenState>();
                    state?._loadUserData();
                  });
                },
                icon: const Icon(Icons.edit),
                label: const Text("Update Profile"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Mobile Delete Account Button (changed to grey)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final state = context.findAncestorStateOfType<_ProfileScreenState>();
                  state?._confirmDeleteAccount();
                },
                icon: const Icon(Icons.delete, color: Colors.white),
                label: const Text("Delete Account"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey, // Changed from red to grey
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
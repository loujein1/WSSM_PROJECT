import 'package:flutter/material.dart';
import 'package:my_dashboard/services/auth_service.dart';

class SidebarWidget extends StatefulWidget {
  const SidebarWidget({super.key});

  @override
  _SidebarWidgetState createState() => _SidebarWidgetState();
}

class _SidebarWidgetState extends State<SidebarWidget> {
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  // ✅ Fetch user role to check for Admin access
  void _checkAdminAccess() async {
    bool adminAccess = await AuthService.canAccessAdminPanel();
    if (mounted) {
      setState(() {
        isAdmin = adminAccess;
      });
    }
  }

  void _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login'); // Navigate to login after logout
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: const Text(
              "Dashboard Menu",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text("Dashboard"),
            onTap: () {
              // Navigate to the dashboard without logging out
              Navigator.pushReplacementNamed(context, '/dashboard');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Account Settings"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/settings');
            },
          ),
          if (isAdmin) // ✅ Dynamically show Admin Panel only for admins
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text("Admin Panel"),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/admin');
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: _logout, // ✅ Call logout function
          ),
        ],
      ),
    );
  }
}
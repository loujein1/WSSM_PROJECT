import 'package:flutter/material.dart';

class NavbarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title; // ✅ Add required title parameter

  const NavbarWidget({super.key, required this.title}); // ✅ Ensure constructor requires title

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), // ✅ Display dynamic title
      backgroundColor: Colors.blueAccent,
      elevation: 4,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("No new notifications")),
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

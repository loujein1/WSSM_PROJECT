import 'package:flutter/material.dart';
import 'widgets/navbar_widget.dart';
import 'widgets/sidebar_widget.dart';

class AppStructure extends StatelessWidget {
  final Widget child;
  final String title; // Title for AppBar

  const AppStructure({super.key, required this.child, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NavbarWidget(title: title), // ✅ Dynamic title
      drawer: const SidebarWidget(), // ✅ Sidebar for navigation
      body: child,
    );
  }
}

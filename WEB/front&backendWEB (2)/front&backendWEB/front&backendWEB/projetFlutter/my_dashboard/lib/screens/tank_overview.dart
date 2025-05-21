import 'package:flutter/material.dart';
import './widgets/alert_widget.dart';
import './widgets/sidebar_widget.dart';
import './widgets/navbar_widget.dart';

class TankOverviewScreen extends StatelessWidget {
  const TankOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double waterLevel = 18; // Example water level for testing

    return Scaffold(
      appBar: AppBar(title: const Text("Water Tank Overview")),
     drawer: SidebarWidget(), // Add the sidebar
     bottomNavigationBar: NavbarWidget(title: 'Tank Overview'), // Provide the required title
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            AlertWidget(waterLevel: waterLevel),
            const SizedBox(height: 10),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text("Tank Status", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: waterLevel / 100,
                      backgroundColor: Colors.grey[300],
                      color: waterLevel < 20 ? Colors.red : Colors.blue,
                    ),
                    const SizedBox(height: 10),
                    Text("Water Level: $waterLevel%", style: TextStyle(fontSize: 18, color: waterLevel < 20 ? Colors.red : Colors.blue)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
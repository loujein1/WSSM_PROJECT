import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart'; // Import AuthService
import '../services/api_service.dart';
import '../models/water_usage.dart';
import '../screens/widgets/line_chart_widget.dart';
import '../screens/widgets/bar_chart_widget.dart';
import '../screens/widgets/pie_chart_widget.dart';
import '../screens/widgets/stats_card_widget.dart';
import '../screens/widgets/sidebar_widget.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

class Dashboard extends StatefulWidget {
  final Map<String, dynamic>? user;
  const Dashboard({super.key, this.user});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late Future<List<WaterUsage>> _futureWaterUsage;
  bool isDarkMode = false;
  bool showChart = false;
  List<String> chartPaths = [];
  String selectedChartPath = "";
  bool isServerAvailable = true;
  bool useLocalChartImage = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
    _fetchData();
    _checkServerStatus();
  }

  void _fetchData() {
    setState(() {
      _futureWaterUsage = ApiService().fetchWaterUsage();
    });
  }

  Future<void> _loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  Future<void> _toggleDarkMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = !isDarkMode;
      prefs.setBool('isDarkMode', isDarkMode);
    });
  }

  Future<void> _checkServerStatus() async {
    try {
      bool available = await ApiService().checkServerAvailable();
      if (mounted) {
        setState(() {
          isServerAvailable = available;
        });
      }
    } catch (e) {
      print("Server check error: $e");
      if (mounted) {
        setState(() {
          isServerAvailable = false;
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.user?['username'] ?? 'Guest';
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        title: Text(
          'IoT Water Usage Dashboard - Welcome, $username!',
        ),
        backgroundColor: isDarkMode ? Colors.lightBlueAccent : Colors.blueAccent,
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: _toggleDarkMode,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      drawer: SidebarWidget(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<WaterUsage>>(
          future: _futureWaterUsage,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No water usage data available.'));
            } else {
              List<WaterUsage> waterUsage = snapshot.data!;
              return LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nouvelle section : Photo statique avec texte de bienvenue
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.purple[100],
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 5,
                              blurRadius: 15,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            Image.asset(
                              'assets/dash.jpg', // This image might be missing
                              width: double.infinity,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Welcome back, $username!',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Get additional 500 GB space for your documents and files. Unlock now for more space.',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Section des StatsCards
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // StatsCard for Current Usage
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(right: 5.0),
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Colors.lightBlueAccent,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                     color: Colors.grey.withOpacity(0.3), // Couleur de l'ombre
        spreadRadius: 5,                   // Étendue de l'ombre
        blurRadius: 15,                    // Flou de l'ombre
        offset: const Offset(0, 4),        // Position de l'ombre (x, y)
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  
                                  Text(
                                    'Current Usage',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '${waterUsage.last.amountUsed} L',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(Icons.water, color: Colors.white),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Water Usage',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // StatsCard for Avg Usage
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5.0),
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Colors.lightBlueAccent,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3), // Couleur de l'ombre
        spreadRadius: 5,                   // Étendue de l'ombre
        blurRadius: 15,                    // Flou de l'ombre
        offset: const Offset(0, 4),        // Position de l'ombre (x, y)
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Avg Usage',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '${(waterUsage.map((e) => e.amountUsed).reduce((a, b) => a + b) / waterUsage.length).toStringAsFixed(2)} L',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(Icons.bar_chart, color: Colors.white),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Average Usage',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // StatsCard for Total Usage
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(left: 5.0),
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Colors.lightBlueAccent,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                   color: Colors.grey.withOpacity(0.3), // Couleur de l'ombre
        spreadRadius: 5,                   // Étendue de l'ombre
        blurRadius: 15,                    // Flou de l'ombre
        offset: const Offset(0, 4),        // Position de l'ombre (x, y)
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Usage',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '${waterUsage.map((e) => e.amountUsed).reduce((a, b) => a + b)} L',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(Icons.pie_chart, color: Colors.white),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Total Usage',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Grille des graphiques et calendrier côte à côte
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Grille des graphiques
                            Expanded(
                              flex: 3, // Prend 3 parts de l'espace
                              child: Column(
                                children: [
                                  // AI Prediction Card
                                  Card(
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                "Analysis Results",
                                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(width: 20),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  if (!isServerAvailable) {
                                                    // First try to check server again
                                                    _checkServerStatus();
                                                    
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Column(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Text("Server unavailable - trying to reconnect..."),
                                                            SizedBox(height: 4),
                                                            Text("Ensure Flask server is running at http://127.0.0.1:5000", 
                                                              style: TextStyle(fontSize: 12)
                                                            ),
                                                          ],
                                                        ),
                                                        backgroundColor: Colors.red,
                                                        duration: Duration(seconds: 4),
                                                        action: SnackBarAction(
                                                          label: 'Retry',
                                                          onPressed: _checkServerStatus,
                                                        ),
                                                      ),
                                                    );
                                                    return;
                                                  }
                                                  
                                                  try {
                                                    // Afficher directement l'image charte.png déjà existante
                                                    setState(() {
                                                      showChart = true;
                                                      // La variable d'état est inutile, on utilise toujours la même image
                                                    });
                                                    
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text("Graphique mis à jour avec succès!"),
                                                        backgroundColor: Colors.green,
                                                        duration: Duration(seconds: 2),
                                                      ),
                                                    );
                                                  } catch (e) {
                                                    print("Erreur: $e");
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text("Erreur: $e"),
                                                        backgroundColor: Colors.red,
                                                        duration: Duration(seconds: 3),
                                                      ),
                                                    );
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: isServerAvailable ? Colors.blue : Colors.grey,
                                                  foregroundColor: Colors.white,
                                                ),
                                                child: Text("Generate Results"),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 30),
                                          if (showChart)
                                            Column(
                                              children: [
                                                Container(
                                                  height: 300,
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: Colors.grey.shade300),
                                                    borderRadius: BorderRadius.circular(8),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.grey.withOpacity(0.1),
                                                        spreadRadius: 1,
                                                        blurRadius: 5,
                                                        offset: Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: Stack(
                                                      children: [
                                                        if (!showChart)
                                                          // Image par défaut qui montre un placeholder
                                                          Container(
                                                            height: 300,
                                                            width: double.infinity,
                                                            decoration: BoxDecoration(
                                                              color: Colors.grey.shade200,
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            child: Center(
                                                              child: Column(
                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                children: [
                                                                  Icon(Icons.insert_chart, size: 64, color: Colors.grey),
                                                                  SizedBox(height: 16),
                                                                  Text("Cliquez sur Générer Résultats pour afficher le graphique",
                                                                    style: TextStyle(color: Colors.grey.shade700),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        
                                                        if (showChart)
                                                          // Affichage de l'image chart.png
                                                          Image.asset(
                                                            'assets/chart.png',
                                                            fit: BoxFit.contain,
                                                            width: double.infinity,
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          else
                                            Container(
                                              height: 300,
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.bar_chart,
                                                      size: 64,
                                                      color: Colors.blue.shade300,
                                                    ),
                                                    SizedBox(height: 16),
                                                    Text(
                                                      "Click 'Generate Results' to view analysis",
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.grey.shade700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  // Existing charts
                                  Expanded(
                                    child: GridView(
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: constraints.maxWidth > 800 ? 3 : 1,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        childAspectRatio: 1.3,
                                      ),
                                      children: [
                                        LineChartWidget(waterUsage: waterUsage),
                                        BarChartWidget(waterUsage: waterUsage),
                                        PieChartWidget(waterUsage: waterUsage),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Marge entre les graphiques et le calendrier
                            const SizedBox(width: 30),

                            // Calendrier à droite
                            Expanded(
                              flex: 1, // Prend 1 part de l'espace
                              child: Container(
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      spreadRadius: 5,
                                      blurRadius: 15,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Calendrier',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TableCalendar(
                                      firstDay: DateTime.utc(2020, 1, 1),
                                      lastDay: DateTime.utc(2030, 12, 31),
                                      focusedDay: DateTime.now(),
                                      calendarFormat: CalendarFormat.month,
                                      startingDayOfWeek: StartingDayOfWeek.monday,
                                      calendarStyle: CalendarStyle(
                                        todayDecoration: BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Liste des événements
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: 1, // Exemple avec 3 événements
                                        itemBuilder: (context, index) {
                                          return ListTile(
                                            leading: CircleAvatar(
                                              backgroundColor: Colors.blueAccent,
                                              child: Icon(
                                                Icons.event,
                                                color: Colors.white,
                                              ),
                                            ),
                                            title: Text(
                                              'Rendez-vous médical',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            subtitle: Text(
                                              'Dr. John Doe - 10 AM',
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
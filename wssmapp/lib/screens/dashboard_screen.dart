import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'material_list_screen.dart';
import 'add_material_screen.dart';
import 'profile_screen.dart';
import '../../constants.dart';
import 'components/background_decoration.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://0397-102-159-238-171.ngrok-free.app'));
  late Future<Map<String, dynamic>> _usageStats;

  @override
  void initState() {
    super.initState();
    _usageStats = _fetchWaterUsageStats();
  }

  Future<Map<String, dynamic>> _fetchWaterUsageStats() async {
    try {
      final response = await _dio.get('/water-usage');
      final List<dynamic> data = response.data;

      double totalUsage = data.fold(0, (sum, entry) => sum + entry['amountUsed']);
      double avgUsage = totalUsage / (data.isNotEmpty ? data.length : 1);

      return {
        "totalUsage": totalUsage,
        "avgUsage": avgUsage,
      };
    } catch (e) {
      print("❌ Error fetching water usage stats: $e");
      return {"totalUsage": 0, "avgUsage": 0};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: Colors.white.withOpacity(0.9), // Ajoutez un fond blanc semi-transparent
        ),
        const BackgroundDecoration(), // Vous pouvez conserver l'effet de fond que vous avez ajouté
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text("Dashboard Water Consumption", style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFFBA68C8),
            foregroundColor: Colors.white,
            elevation: 3,
            actions: [
              IconButton(
                icon: const Icon(Icons.account_circle, size: 28),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileScreen()),
                  );
                },
              ),
            ],
          ),
          body: FutureBuilder<Map<String, dynamic>>(
            future: _usageStats,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(child: Text('❌ Erreur lors du chargement'));
              }

              if (!snapshot.hasData) {
                return const Center(child: Text('Aucune donnée trouvée'));
              }

              final data = snapshot.data!;
              final totalUsage = data['totalUsage'] ?? 0;
              final avgUsage = data['avgUsage'] ?? 0;

              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE1BEE7), Color(0xFFCE93D8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
                      child: Column(
                        children: [
                          const Text(
                            "💧 Consommation Totale",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${totalUsage.toStringAsFixed(2)} litres",
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "📊 Moyenne Journalière",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${avgUsage.toStringAsFixed(2)} litres",
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MaterialListScreen()),
                        );
                      },
                      icon: const Icon(Icons.view_list, color: Colors.white),
                      label: Text(
                        "Voir les Matériaux".toUpperCase(),
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
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AddMaterialScreen()),
                        );
                      },
                      icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                      label: Text(
                        "Ajouter Matérial".toUpperCase(),
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
            },
          ),
        ),
      ],
    );
  }
}


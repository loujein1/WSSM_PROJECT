import 'package:flutter/material.dart';
import 'package:wssmapp/services/api_service.dart';
import 'material_detail_screen.dart';
import '../responsive.dart';
import 'components/background_decoration.dart';
import '../../constants.dart';

class MaterialListScreen extends StatefulWidget {
  const MaterialListScreen({super.key});

  @override
  _MaterialListScreenState createState() => _MaterialListScreenState();
}

class _MaterialListScreenState extends State<MaterialListScreen> {
  List<dynamic> materials = [];
  final ApiService apiService = ApiService();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getMaterials();
  }

  Future<void> _getMaterials() async {
    try {
      var response = await apiService.getUserMaterials();
      setState(() {
        materials = response;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error fetching materials: $e");
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load materials")),
      );
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
            child: Column(
              children: [
                AppBar(
                  title: const Text("Materials List"),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : materials.isEmpty
                          ? Center(
                              child: Text(
                                "No materials found",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : Responsive(
                              mobile: _buildMobileList(),
                              desktop: _buildDesktopList(),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      padding: const EdgeInsets.all(defaultPadding),
      itemCount: materials.length,
      itemBuilder: (context, index) {
        var material = materials[index];
        return Card(
          margin: const EdgeInsets.only(bottom: defaultPadding),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            title: Text(
              material['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(material['description']),
            trailing: IconButton(
              icon: const Icon(Icons.info, color: kPrimaryColor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MaterialDetailScreen(material: material),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopList() {
    return Center(
      child: SizedBox(
        width: 600,
        child: ListView.builder(
          padding: const EdgeInsets.all(defaultPadding),
          itemCount: materials.length,
          itemBuilder: (context, index) {
            var material = materials[index];
            return Card(
              margin: const EdgeInsets.only(bottom: defaultPadding),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                title: Text(
                  material['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(material['description']),
                trailing: IconButton(
                  icon: const Icon(Icons.info, color: kPrimaryColor),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MaterialDetailScreen(material: material),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
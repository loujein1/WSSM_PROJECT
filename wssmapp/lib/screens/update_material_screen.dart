import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'material_list_screen.dart';

class UpdateMaterialScreen extends StatefulWidget {
  final Map<String, dynamic> material;

  const UpdateMaterialScreen({super.key, required this.material});

  @override
  _UpdateMaterialScreenState createState() => _UpdateMaterialScreenState();
}

class _UpdateMaterialScreenState extends State<UpdateMaterialScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://0397-102-159-238-171.ngrok-free.app'));

  @override
  void initState() {
    super.initState();
    nameController.text = widget.material['name'] ?? '';
    descriptionController.text = widget.material['description'] ?? '';
  }

  // 🔹 Update Material Function
Future<void> _updateMaterial() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('userId') ?? '';

    print("🛠️ Updating Material ID: ${widget.material['_id']} for User: $userId");

    final response = await _dio.patch(
      '/materials/${widget.material['_id']}',
      data: {
        'name': nameController.text.trim(),
        'description': descriptionController.text.trim(),
      },
    );

    print("✅ API Response: ${response.data}");

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Material updated successfully!")),
      );

      // Update SharedPreferences if needed
      prefs.setString('lastUpdatedMaterial', widget.material['_id']);

      // Navigate back to Material List
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MaterialListScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to update material")),
      );
    }
  } catch (e) {
    print("❌ Error updating material: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ Error updating material")),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Update Material")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Material Name"),
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: "Description"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateMaterial,
              child: Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }
}

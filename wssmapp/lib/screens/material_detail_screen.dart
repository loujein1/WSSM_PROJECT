import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';
import '../responsive.dart';
import 'components/background_decoration.dart';
import '../../constants.dart';
import 'update_material_screen.dart';
import 'material_list_screen.dart';

class MaterialDetailScreen extends StatelessWidget {
  final Map<String, dynamic> material;

  MaterialDetailScreen({super.key, required this.material});

  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://0397-102-159-238-171.ngrok-free.app'));

  Future<void> _deleteMaterial(BuildContext context) async {
    try {
      final response = await _dio.delete('/materials/${material['_id']}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Material deleted successfully!")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MaterialListScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Failed to delete material")),
        );
      }
    } catch (e) {
      print("❌ Error deleting material: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Error deleting material")),
      );
    }
  }

  void _scanQRCode(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(),
      ),
    );
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
                  mobile: _buildMobileDetail(),
                  desktop: SizedBox(
                    width: 600,
                    child: _buildDesktopDetail(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDetail() {
    return Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppBar(
            title: Text(material['name'] ?? "Material Details"),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
          ),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Material Name:", 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor),
                        textAlign: TextAlign.center),
                    Text(material['name'] ?? "No Name", 
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    Text("Description:", 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor),
                        textAlign: TextAlign.center),
                    Text(material['description'] ?? "No Description", 
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    Text("Created At:", 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor),
                        textAlign: TextAlign.center),
                    Text(material['createdAt'] ?? "Unknown", 
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildDesktopDetail() {
    return Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppBar(
            title: Text(material['name'] ?? "Material Details"),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
          ),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Material Name:", 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor),
                        textAlign: TextAlign.center),
                    Text(material['name'] ?? "No Name", 
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    Text("Description:", 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor),
                        textAlign: TextAlign.center),
                    Text(material['description'] ?? "No Description", 
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    Text("Created At:", 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor),
                        textAlign: TextAlign.center),
                    Text(material['createdAt'] ?? "Unknown", 
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Builder(
      builder: (context) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UpdateMaterialScreen(material: material),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text("Update"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: () => _deleteMaterial(context),
                    icon: const Icon(Icons.delete),
                    label: const Text("Delete"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _scanQRCode(context),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text("Scan QR Code"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class QRScannerScreen extends StatelessWidget {
  const QRScannerScreen({super.key});

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
                  title: const Text("Scan QR Code"),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  centerTitle: true,
                ),
                Expanded(
                  child: Center(
                    child: MobileScanner(
                      onDetect: (capture) {
                        final List<Barcode> barcodes = capture.barcodes;
                        if (barcodes.isNotEmpty) {
                          String scannedData = barcodes.first.rawValue ?? "Unknown QR Code";
                          print("✅ QR Code Scanned: $scannedData");
                          _showScannedDataDialog(context, scannedData);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showScannedDataDialog(BuildContext context, String scannedData) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("QR Code Scanned"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(scannedData, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: scannedData));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("✅ Scanned data copied to clipboard")),
                  );
                },
                child: const Text("Copy to Clipboard"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }
}
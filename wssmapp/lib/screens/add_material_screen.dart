import 'package:flutter/material.dart';
import 'package:wssmapp/services/api_service.dart';
import '../responsive.dart';
import 'components/background_decoration.dart';
import '../../constants.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AddMaterialScreen extends StatefulWidget {
  const AddMaterialScreen({super.key});

  @override
  _AddMaterialScreenState createState() => _AddMaterialScreenState();
}

class _AddMaterialScreenState extends State<AddMaterialScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final ApiService apiService = ApiService();

  void _addMaterial() async {
    String name = nameController.text.trim();
    String description = descriptionController.text.trim();

    if (name.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields.")),
      );
      return;
    }

    try {
      await apiService.addMaterial(name, description);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Material added successfully!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to add material")),
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
            child: Center(
              child: SingleChildScrollView(
                child: Responsive(
                  mobile: const MobileAddMaterialScreen(),
                  desktop: SizedBox(
                    width: 450,
                    child: _buildAddMaterialForm(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddMaterialForm() {
    return Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Added image here
          Image.asset(
            'assets/images/material.jpeg',
            height: 150,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          Text(
            "Add New Material",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              hintText: "Material Name",
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: defaultPadding),
                child: Icon(Icons.construction, color: kPrimaryColor),
              ),
              filled: true,
              fillColor: kPrimaryLightColor,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(inputBorderRadius),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(inputBorderRadius),
                borderSide: const BorderSide(color: kPrimaryColor),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: descriptionController,
            decoration: InputDecoration(
              hintText: "Material Description",
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: defaultPadding),
                child: Icon(Icons.description, color: kPrimaryColor),
              ),
              filled: true,
              fillColor: kPrimaryLightColor,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(inputBorderRadius),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(inputBorderRadius),
                borderSide: const BorderSide(color: kPrimaryColor),
              ),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _addMaterial,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              "Add Material".toUpperCase(),
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
  }
}

class MobileAddMaterialScreen extends StatelessWidget {
  const MobileAddMaterialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/material.png',
            height: 120,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          const _AddMaterialForm(),
        ],
      ),
    );
  }
}

class _AddMaterialForm extends StatelessWidget {
  const _AddMaterialForm();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_AddMaterialScreenState>();
    return Column(
      children: [
        Text(
          "Add New Material",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: state?.nameController,
          decoration: InputDecoration(
            hintText: "Material Name",
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: defaultPadding),
              child: Icon(Icons.construction, color: kPrimaryColor),
            ),
            filled: true,
            fillColor: kPrimaryLightColor,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(inputBorderRadius),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(inputBorderRadius),
              borderSide: const BorderSide(color: kPrimaryColor),
            ),
          ),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: state?.descriptionController,
          decoration: InputDecoration(
            hintText: "Material Description",
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: defaultPadding),
              child: Icon(Icons.description, color: kPrimaryColor),
            ),
            filled: true,
            fillColor: kPrimaryLightColor,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(inputBorderRadius),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(inputBorderRadius),
              borderSide: const BorderSide(color: kPrimaryColor),
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: state?._addMaterial,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            "Add Material".toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
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
            minimumSize: const Size(double.infinity, 50),
            elevation: 8,
            shadowColor: kPrimaryColor.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}
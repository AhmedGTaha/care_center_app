import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../models/equipment_model.dart';
import '../../services/equipment_service.dart';

class EquipmentForm extends StatefulWidget {
  const EquipmentForm({super.key});

  @override
  State<EquipmentForm> createState() => _EquipmentFormState();
}

class _EquipmentFormState extends State<EquipmentForm> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final quantityCtrl = TextEditingController();
  final priceCtrl = TextEditingController();

  String? selectedType;
  String? selectedCondition;

  File? selectedImage;

  final service = EquipmentService();

  final List<String> equipmentTypes = [
    "Wheelchair",
    "Walker",
    "Crutches",
    "Hospital Bed",
    "Oxygen Machine",
    "Medical Monitor",
    "Mobility Scooter",
    "Hoist / Lift",
    "Chair",
    "Other",
  ];

  final List<String> conditions = [
    "New",
    "Used",
    "Like New",
  ];

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery);

    if (result != null) {
      setState(() => selectedImage = File(result.path));
    }
  }

  Future<String> uploadImage(File file) async {
    final fileName = "equipment_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final ref = FirebaseStorage.instance.ref().child("equipment/$fileName");

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Equipment")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Name"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Type"),
                value: selectedType,
                items: equipmentTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (value) => setState(() => selectedType = value),
                validator: (v) => v == null ? "Please select a type" : null,
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 3,
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Condition"),
                value: selectedCondition,
                items: conditions
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) => setState(() => selectedCondition = value),
                validator: (v) => v == null ? "Please select a condition" : null,
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: quantityCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Quantity"),
                validator: (v) => int.tryParse(v!) == null ? "Enter a number" : null,
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Price Per Day"),
                validator: (v) => double.tryParse(v!) == null ? "Enter a valid number" : null,
              ),

              const SizedBox(height: 20),

              // ⭐ Image Picker
              GestureDetector(
                onTap: pickImage,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundImage: selectedImage != null
                          ? FileImage(selectedImage!)
                          : const AssetImage("assets/default_equipment.png")
                              as ImageProvider,
                    ),
                    const SizedBox(height: 10),
                    const Text("Select Image"),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  String uploadedImageUrl = "";

                  // Upload image only if selected
                  if (selectedImage != null) {
                    uploadedImageUrl = await uploadImage(selectedImage!);
                  }

                  final eq = Equipment(
                    id: "",
                    name: nameCtrl.text.trim(),
                    type: selectedType!,
                    description: descCtrl.text.trim(),
                    imageUrl: uploadedImageUrl, // fallback handled in UI
                    condition: selectedCondition!,
                    quantity: int.parse(quantityCtrl.text),
                    status: "available",
                    pricePerDay: double.parse(priceCtrl.text),
                  );

                  await service.addEquipment(eq);

                  if (!mounted) return;
                  Navigator.pop(context);
                },
                child: const Text("Save Equipment"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
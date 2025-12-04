import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../models/equipment_model.dart';
import '../../services/equipment_service.dart';

class EquipmentForm extends StatefulWidget {
  final Equipment? equipment; // null = add, not null = edit

  const EquipmentForm({super.key, this.equipment});

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
  String existingImageUrl = "";

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

  @override
  void initState() {
    super.initState();

    // ⭐ If editing → prefill all fields
    if (widget.equipment != null) {
      final eq = widget.equipment!;

      nameCtrl.text = eq.name;
      descCtrl.text = eq.description;
      quantityCtrl.text = eq.quantity.toString();
      priceCtrl.text = eq.pricePerDay.toString();

      selectedType = eq.type;
      selectedCondition = eq.condition;
      existingImageUrl = eq.imageUrl;
    }
  }

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
    final isEditing = widget.equipment != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Equipment" : "Add Equipment"),
      ),
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

              // ⭐ TYPE DROPDOWN
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Type"),
                initialValue: selectedType,
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

              // ⭐ CONDITION DROPDOWN
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Condition"),
                initialValue: selectedCondition,
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
                validator: (v) =>
                    double.tryParse(v!) == null ? "Enter a valid number" : null,
              ),

              const SizedBox(height: 20),

              // ⭐ IMAGE PICKER WITH EXISTING IMAGE SUPPORT
              GestureDetector(
                onTap: pickImage,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundImage: selectedImage != null
                          ? FileImage(selectedImage!)
                          : (existingImageUrl.isNotEmpty
                                  ? NetworkImage(existingImageUrl)
                                  : const AssetImage("assets/default_equipment.png")
                             ) as ImageProvider,
                    ),
                    const SizedBox(height: 10),
                    Text(isEditing ? "Change Image" : "Select Image"),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  String finalImageUrl = existingImageUrl;

                  // Upload new image if selected
                  if (selectedImage != null) {
                    finalImageUrl = await uploadImage(selectedImage!);
                  }

                  final eq = Equipment(
                    id: widget.equipment?.id ?? "",
                    name: nameCtrl.text.trim(),
                    type: selectedType!,
                    description: descCtrl.text.trim(),
                    imageUrl: finalImageUrl,
                    condition: selectedCondition!,
                    quantity: int.parse(quantityCtrl.text),
                    status: "available",
                    pricePerDay: double.parse(priceCtrl.text),
                  );

                  if (isEditing) {
                    await service.updateEquipment(eq);
                  } else {
                    await service.addEquipment(eq);
                  }

                  if (!mounted) return;

                  Navigator.pop(context);
                },
                child: Text(isEditing ? "Update Equipment" : "Save Equipment"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../models/equipment_model.dart';
import '../../services/equipment_service.dart';

class EquipmentForm extends StatefulWidget {
  final Equipment? equipment;

  const EquipmentForm({super.key, this.equipment});

  @override
  State<EquipmentForm> createState() => _EquipmentFormState();
}

class _EquipmentFormState extends State<EquipmentForm> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final priceCtrl = TextEditingController();

  String? selectedType;
  String? selectedCondition;

  int quantity = 1;
  bool loading = false;

  File? selectedImage;
  String oldImagePath = "";

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

  final List<String> conditions = ["New", "Used", "Like New"];

  @override
  void initState() {
    super.initState();

    if (widget.equipment != null) {
      final eq = widget.equipment!;
      nameCtrl.text = eq.name;
      descCtrl.text = eq.description;
      priceCtrl.text = eq.pricePerDay.toString();
      quantity = eq.quantity;

      selectedType = eq.type;
      selectedCondition = eq.condition;
      oldImagePath = eq.imagePath;
    }
  }

  // -------------------- PICK + COMPRESS IMAGE --------------------
  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final compressed = await FlutterImageCompress.compressAndGetFile(
      picked.path,
      "${picked.path}_compressed.jpg",
      quality: 60,
    );

    setState(() => selectedImage = File(compressed?.path ?? picked.path));
  }

  void setLoading(bool state) => setState(() => loading = state);

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.equipment != null;

    return Stack(
      children: [
        Scaffold(
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

                  DropdownButtonFormField<String>(
                    value: selectedType,
                    items: equipmentTypes
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedType = v),
                    validator: (v) => v == null ? "Select type" : null,
                    decoration: const InputDecoration(labelText: "Type"),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: "Description"),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: selectedCondition,
                    items: conditions
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedCondition = v),
                    validator: (v) => v == null ? "Select condition" : null,
                    decoration: const InputDecoration(labelText: "Condition"),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Text("Quantity"),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: quantity > 1
                            ? () => setState(() => quantity--)
                            : null,
                      ),
                      Text(quantity.toString(),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        onPressed: () => setState(() => quantity++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: priceCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*$')),
                    ],
                    decoration:
                        const InputDecoration(labelText: "Price Per Day"),
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Enter price";
                      final n = double.tryParse(v);
                      if (n == null || n <= 0) return "Must be > 0";
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: pickImage,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundImage: selectedImage != null
                              ? FileImage(selectedImage!)
                              : (oldImagePath.isNotEmpty &&
                                      File(oldImagePath).existsSync()
                                  ? FileImage(File(oldImagePath))
                                  : const AssetImage(
                                      "assets/default_equipment.png"))
                                  as ImageProvider,
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

                      setLoading(true);

                      String newImagePath = oldImagePath;

                      if (selectedImage != null) {
                        newImagePath =
                            await service.saveLocalImage(selectedImage!);
                      }

                      final eq = Equipment(
                        id: widget.equipment?.id ?? "",
                        name: nameCtrl.text.trim(),
                        type: selectedType!,
                        description: descCtrl.text.trim(),
                        imagePath: newImagePath,
                        condition: selectedCondition!,
                        quantity: quantity,
                        status: "available",
                        pricePerDay: double.parse(priceCtrl.text),
                      );

                      if (isEditing) {
                        await service.updateEquipment(eq,
                            oldImagePath: oldImagePath);
                      } else {
                        await service.addEquipment(eq);
                      }

                      setLoading(false);
                      if (!mounted) return;

                      Navigator.pop(context);
                    },
                    child: Text(isEditing ? "Update Equipment" : "Save"),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (loading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }
}
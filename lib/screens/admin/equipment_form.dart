import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../models/equipment_model.dart';
import '../../services/equipment_service.dart';

class EquipmentForm extends StatefulWidget {
  final Equipment? equipment;
  final bool isFromDonation;

  const EquipmentForm({
    super.key,
    this.equipment,
    this.isFromDonation = false,
  });

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

  final List<String> types = [
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

  final List<String> conditions = ["New", "Like New", "Good", "Fair", "Poor"];

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

  @override
  Widget build(BuildContext context) {
    final bool isEditing =
        widget.equipment != null && widget.isFromDonation == false;

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
                    items: types
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedType = v),
                    validator: (v) => v == null ? "Required" : null,
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
                    validator: (v) => v == null ? "Required" : null,
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
                      Text("$quantity",
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
                        RegExp(r'^\d*\.?\d*$'),
                      ),
                    ],
                    decoration:
                        const InputDecoration(labelText: "Price Per Day"),
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Required";
                      return double.tryParse(v) != null ? null : "Invalid";
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

                      setState(() => loading = true);

                      String finalImage = oldImagePath;
                      if (selectedImage != null) {
                        finalImage =
                            await service.saveLocalImage(selectedImage!);
                      }

                      final eq = Equipment(
                        id: isEditing ? widget.equipment!.id : "",
                        name: nameCtrl.text,
                        type: selectedType!,
                        description: descCtrl.text,
                        imagePath: finalImage,
                        condition: selectedCondition!,
                        quantity: quantity,
                        status: "available",
                        pricePerDay: double.parse(priceCtrl.text),
                      );

                      if (widget.isFromDonation) {
                        await service.addEquipment(eq);
                      } else if (isEditing) {
                        await service.updateEquipment(eq, oldImagePath: oldImagePath);
                      } else {
                        await service.addEquipment(eq);
                      }

                      setState(() => loading = false);
                      if (!mounted) return;
                      Navigator.pop(context);
                    },
                    child:
                        Text(isEditing ? "Update Equipment" : "Save Equipment"),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (loading)
          Container(
            color: Colors.black45,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }
}
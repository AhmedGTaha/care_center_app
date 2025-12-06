import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/equipment_model.dart';
import '../../services/equipment_service.dart';
import '../../services/image_service.dart';
import 'dart:typed_data';

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
  final locationCtrl = TextEditingController();
  final tagCtrl = TextEditingController();

  String? selectedType;
  String? selectedCondition;

  int quantity = 1;
  bool loading = false;
  String loadingMessage = "";

  XFile? selectedImage;
  String oldImagePath = "";

  List<String> tags = [];

  final service = EquipmentService();
  final imageService = ImageService();

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
      locationCtrl.text = eq.location;
      quantity = eq.quantity;
      selectedType = eq.type;
      selectedCondition = eq.condition;
      oldImagePath = eq.imagePath;
      tags = List.from(eq.tags);
    }
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => selectedImage = picked);
  }

  void addTag() {
    final tag = tagCtrl.text.trim();
    if (tag.isNotEmpty && !tags.contains(tag)) {
      setState(() {
        tags.add(tag);
        tagCtrl.clear();
      });
    }
  }

  void removeTag(String tag) {
    setState(() {
      tags.remove(tag);
    });
  }

  Future<void> _saveEquipment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      loadingMessage = "Preparing to save...";
    });

    try {
      String finalImage = oldImagePath;
      
      if (selectedImage != null) {
        setState(() => loadingMessage = "Uploading image...");
        
        try {
          finalImage = await service.saveLocalImage(selectedImage!);
          debugPrint('Image saved successfully: $finalImage');
        } catch (e) {
          setState(() => loading = false);
          if (!mounted) return;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Image upload failed: ${e.toString()}"),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
          return;
        }
      }

      setState(() => loadingMessage = "Saving equipment...");

      String equipmentStatus = "available";
      if (widget.isFromDonation) {
        equipmentStatus = "donated";
      }

      final eq = Equipment(
        id: widget.equipment?.id ?? "",
        name: nameCtrl.text.trim(),
        type: selectedType!,
        description: descCtrl.text.trim(),
        imagePath: finalImage,
        condition: selectedCondition!,
        quantity: quantity,
        status: equipmentStatus,
        pricePerDay: double.parse(priceCtrl.text),
        location: locationCtrl.text.trim(),
        tags: tags,
      );

      if (widget.isFromDonation || widget.equipment == null) {
        await service.addEquipment(eq);
      } else {
        await service.updateEquipment(eq, oldImagePath: oldImagePath);
      }

      setState(() => loading = false);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Equipment saved successfully!"),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context);
    } catch (e) {
      setState(() => loading = false);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.isFromDonation)
                    Container(
                      padding: const EdgeInsets.all(15),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.volunteer_activism,
                              color: Colors.blue.shade700, size: 30),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Adding Donated Equipment",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "This equipment will be marked as donated with status: DONATED",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: "Name *",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.medical_services),
                    ),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 15),

                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: "Type *",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: types
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedType = v),
                    validator: (v) => v == null ? "Required" : null,
                  ),
                  const SizedBox(height: 15),

                  TextFormField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Description",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 15),

                  DropdownButtonFormField<String>(
                    value: selectedCondition,
                    decoration: const InputDecoration(
                      labelText: "Condition *",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.star),
                    ),
                    items: conditions
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedCondition = v),
                    validator: (v) => v == null ? "Required" : null,
                  ),
                  const SizedBox(height: 15),

                  TextFormField(
                    controller: locationCtrl,
                    decoration: const InputDecoration(
                      labelText: "Location",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                      hintText: "e.g., Room 201, Storage A",
                    ),
                  ),
                  const SizedBox(height: 15),

                  Row(
                    children: [
                      const Text(
                        "Quantity *",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: quantity > 1
                            ? () => setState(() => quantity--)
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                        child: Text(
                          "$quantity",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        onPressed: () => setState(() => quantity++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  TextFormField(
                    controller: priceCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d*$'),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: "Price Per Day (BD) *",
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.payments),
                      hintText: widget.isFromDonation
                          ? "0.00 (Donated - Free)"
                          : "0.00 for free/donated items",
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Required";
                      return double.tryParse(v) != null ? null : "Invalid";
                    },
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    "Tags",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: tagCtrl,
                          decoration: const InputDecoration(
                            hintText: "Add tag (e.g., pediatric, portable)",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.label),
                          ),
                          onFieldSubmitted: (_) => addTag(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: addTag,
                        icon: const Icon(Icons.add),
                        label: const Text("Add"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (tags.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () => removeTag(tag),
                          backgroundColor: Colors.blue.shade50,
                          deleteIconColor: Colors.blue,
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 20),

                  const Text(
                    "Equipment Image *",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: kIsWeb
                                  ? FutureBuilder<Uint8List>(
                                      future: selectedImage!.readAsBytes(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          return Image.memory(
                                            snapshot.data!,
                                            fit: BoxFit.cover,
                                          );
                                        }
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      },
                                    )
                                  : Image.file(
                                      File(selectedImage!.path),
                                      fit: BoxFit.cover,
                                    ),
                            )
                          : (oldImagePath.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: imageService.getImageWidget(
                                    oldImagePath,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_alt,
                                        size: 50, color: Colors.grey.shade600),
                                    const SizedBox(height: 10),
                                    Text(
                                      isEditing ? "Change Image" : "Tap to add image",
                                      style: TextStyle(color: Colors.grey.shade600),
                                    ),
                                  ],
                                )),
                    ),
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : _saveEquipment,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        isEditing ? "Update Equipment" : "Save Equipment",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (loading)
          Container(
            color: Colors.black54,
            child: Center(
              child: Card(
                margin: const EdgeInsets.all(20),
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: Colors.blue,
                        strokeWidth: 4,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        loadingMessage,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Please wait...",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    priceCtrl.dispose();
    locationCtrl.dispose();
    tagCtrl.dispose();
    super.dispose();
  }
}
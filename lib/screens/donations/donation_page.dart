import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/donation_service.dart';

class DonationPage extends StatefulWidget {
  const DonationPage({super.key});

  @override
  State<DonationPage> createState() => _DonationPageState();
}

class _DonationPageState extends State<DonationPage> {
  final _formKey = GlobalKey<FormState>();

  final itemCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  String type = "Wheelchair";
  String condition = "Good";     // ⭐ DEFAULT VALUE

  int quantity = 1;

  File? selectedImage;
  final service = DonationService();

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => selectedImage = File(picked.path));
    }
  }

  Future<String> saveDonationImage(File file) async {
    final dir = await getApplicationDocumentsDirectory();
    final donateDir = Directory("${dir.path}/donations");

    if (!donateDir.existsSync()) {
      donateDir.createSync(recursive: true);
    }

    final output =
        "${donateDir.path}/don_${DateTime.now().millisecondsSinceEpoch}.jpg";

    final compressed = await FlutterImageCompress.compressAndGetFile(
      file.path,
      output,
      quality: 70,
    );

    return compressed?.path ?? "";
  }

  Future<void> submitDonation() async {
    if (!_formKey.currentState!.validate() || selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Complete all fields and upload an image")),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final path = await saveDonationImage(selectedImage!);

    await service.submitDonation(
      userId: uid,
      itemName: itemCtrl.text.trim(),
      type: type,
      description: descCtrl.text.trim(),
      imagePath: path,
      quantity: quantity,
      condition: condition,   // ⭐ NEW FIELD
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Donation submitted successfully")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Donate Equipment"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: pickImage,
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage:
                      selectedImage != null ? FileImage(selectedImage!) : null,
                  child: selectedImage == null
                      ? const Icon(Icons.camera_alt, size: 30)
                      : null,
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: itemCtrl,
                decoration: const InputDecoration(labelText: "Item Name"),
                validator: (v) => v!.isEmpty ? "Enter the equipment name" : null,
              ),

              const SizedBox(height: 15),

              DropdownButtonFormField(
                decoration: const InputDecoration(labelText: "Type"),
                value: type,
                items: const [
                  DropdownMenuItem(value: "Wheelchair", child: Text("Wheelchair")),
                  DropdownMenuItem(value: "Walker", child: Text("Walker")),
                  DropdownMenuItem(value: "Crutches", child: Text("Crutches")),
                  DropdownMenuItem(value: "Bed", child: Text("Hospital Bed")),
                  DropdownMenuItem(value: "Other", child: Text("Other")),
                ],
                onChanged: (v) => setState(() => type = v!),
              ),

              const SizedBox(height: 15),

              // ⭐ NEW CONDITION DROPDOWN
              DropdownButtonFormField(
                decoration: const InputDecoration(labelText: "Condition"),
                value: condition,
                items: const [
                  DropdownMenuItem(value: "New", child: Text("New")),
                  DropdownMenuItem(value: "Like New", child: Text("Like New")),
                  DropdownMenuItem(value: "Good", child: Text("Good")),
                  DropdownMenuItem(value: "Fair", child: Text("Fair")),
                  DropdownMenuItem(value: "Poor", child: Text("Poor")),
                ],
                onChanged: (v) => setState(() => condition = v!),
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  const Text("Quantity", style: TextStyle(fontSize: 16)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: quantity > 1
                        ? () => setState(() => quantity--)
                        : null,
                  ),
                  Text(
                    quantity.toString(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    onPressed: () => setState(() => quantity++),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? "Enter a description" : null,
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: submitDonation,
                  child: const Text("Submit Donation"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  File? selectedImage;
  final service = DonationService();

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => selectedImage = File(picked.path));
    }
  }

  Future<void> submitDonation() async {
    if (!_formKey.currentState!.validate() || selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Complete all fields and upload an image")),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final imageUrl = await service.uploadDonationImage(selectedImage!);

    await service.submitDonation(
      userId: uid,
      itemName: itemCtrl.text,
      type: type,
      description: descCtrl.text,
      imageUrl: imageUrl,
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
                validator: (v) =>
                    v!.isEmpty ? "Enter the equipment name" : null,
              ),

              const SizedBox(height: 15),

              DropdownButtonFormField(
                decoration: const InputDecoration(labelText: "Type"),
                initialValue: type,
                items: const [
                  DropdownMenuItem(value: "Wheelchair", child: Text("Wheelchair")),
                  DropdownMenuItem(value: "Walker", child: Text("Walker")),
                  DropdownMenuItem(value: "Crutches", child: Text("Crutches")),
                  DropdownMenuItem(value: "Bed", child: Text("Hospital Bed")),
                  DropdownMenuItem(value: "Oxygen Machine", child: Text("Oxygen Machine")),
                  DropdownMenuItem(value: "Medical Monitor", child: Text("Medical Monitor")),
                  DropdownMenuItem(value: "Mobility Scooter", child: Text("Mobility Scooter")),
                  DropdownMenuItem(value: "Hoist", child: Text("Lift / Hoist")),
                  DropdownMenuItem(value: "Chair", child: Text("Hospital Chair")),
                  DropdownMenuItem(value: "Other", child: Text("Other")),
                ],
                onChanged: (value) {
                  setState(() => type = value!);
                },
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 3,
                validator: (v) =>
                    v!.isEmpty ? "Enter a description" : null,
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: submitDonation,
                  child: const Text("Submit Donation"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
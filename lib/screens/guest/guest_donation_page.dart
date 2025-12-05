import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GuestDonationPage extends StatefulWidget {
  const GuestDonationPage({super.key});

  @override
  State<GuestDonationPage> createState() => _GuestDonationPageState();
}

class _GuestDonationPageState extends State<GuestDonationPage> {
  final _formKey = GlobalKey<FormState>();
  final itemCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  String type = "Wheelchair";
  String condition = "Good";
  int quantity = 1;
  File? selectedImage;
  bool submitting = false;

  // Guest fixed info
  final String guestUserId = "guest_user"; // Fixed guest user ID
  final String guestName = "Guest";
  final String guestEmail = "guest@example.com";
  final String guestPhone = "00000000";

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => selectedImage = File(picked.path));
    }
  }

  Future<String> saveDonationImage(File file) async {
    try {
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
    } catch (e) {
      debugPrint("Error saving donation image: $e");
      return "";
    }
  }

  Future<void> submitDonation() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please complete all required fields"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please upload an image of the equipment"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => submitting = true);

    try {
      final path = await saveDonationImage(selectedImage!);

      // Submit donation with guest info
      await FirebaseFirestore.instance.collection("donations").add({
        "userId": guestUserId, // Use fixed guest user ID
        "itemName": itemCtrl.text.trim(),
        "type": type,
        "description": descCtrl.text.trim(),
        "imagePath": path,
        "quantity": quantity,
        "condition": condition,
        "status": "pending",
        "createdAt": Timestamp.now(),
        // Store guest info
        "donorName": guestName,
        "donorEmail": guestEmail,
        "donorPhone": guestPhone,
        "isGuest": true,
      });

      setState(() => submitting = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Donation submitted successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() => submitting = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error submitting donation: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Donate Equipment (Guest)"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Guest Info Notice
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 10),
                        const Text(
                          "Guest Donation",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Your donation will be submitted as:",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    _infoRow(Icons.person, "Name", guestName),
                    _infoRow(Icons.email, "Email", guestEmail),
                    _infoRow(Icons.phone, "Phone", guestPhone),
                    const SizedBox(height: 10),
                    Text(
                      "Create an account to personalize your donations!",
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // Image Picker
              const Text(
                "Equipment Photo *",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                          child: Image.file(
                            selectedImage!,
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
                              "Tap to add photo",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Item Name
              TextFormField(
                controller: itemCtrl,
                decoration: const InputDecoration(
                  labelText: "Item Name *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medical_services),
                ),
                validator: (v) =>
                    v!.isEmpty ? "Enter the equipment name" : null,
              ),

              const SizedBox(height: 15),

              // Type Dropdown
              DropdownButtonFormField(
                decoration: const InputDecoration(
                  labelText: "Type *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                initialValue: type,
                items: const [
                  DropdownMenuItem(
                      value: "Wheelchair", child: Text("Wheelchair")),
                  DropdownMenuItem(value: "Walker", child: Text("Walker")),
                  DropdownMenuItem(value: "Crutches", child: Text("Crutches")),
                  DropdownMenuItem(
                      value: "Hospital Bed", child: Text("Hospital Bed")),
                  DropdownMenuItem(
                      value: "Oxygen Machine", child: Text("Oxygen Machine")),
                  DropdownMenuItem(
                      value: "Medical Monitor", child: Text("Medical Monitor")),
                  DropdownMenuItem(
                      value: "Mobility Scooter",
                      child: Text("Mobility Scooter")),
                  DropdownMenuItem(
                      value: "Hoist / Lift", child: Text("Hoist / Lift")),
                  DropdownMenuItem(value: "Chair", child: Text("Chair")),
                  DropdownMenuItem(value: "Other", child: Text("Other")),
                ],
                onChanged: (v) => setState(() => type = v!),
              ),

              const SizedBox(height: 15),

              // Condition Dropdown
              DropdownButtonFormField(
                decoration: const InputDecoration(
                  labelText: "Condition *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.star),
                ),
                initialValue: condition,
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

              // Quantity
              Row(
                children: [
                  const Text("Quantity *",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: quantity > 1
                        ? () => setState(() => quantity--)
                        : null,
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                    child: Text(
                      quantity.toString(),
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

              // Description
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: "Description *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (v) => v!.isEmpty ? "Enter a description" : null,
              ),

              const SizedBox(height: 25),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: submitting ? null : submitDonation,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Submit Donation",
                          style: TextStyle(
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
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Text(
            "$label:",
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    itemCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }
}
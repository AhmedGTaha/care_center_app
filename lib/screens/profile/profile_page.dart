import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/image_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final userIdCtrl = TextEditingController();
  
  String preferredContact = "Email";
  String role = "";
  String avatarUrl = "";
  
  XFile? newAvatar;
  bool loading = true;
  bool editing = false;
  bool saving = false;

  final ImageService _imageService = ImageService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => loading = true);
    
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      nameCtrl.text = data["name"] ?? "";
      emailCtrl.text = data["email"] ?? "";
      phoneCtrl.text = data["phone"] ?? "";
      userIdCtrl.text = data["uid"] ?? "";
      role = data["role"] ?? "renter";
      avatarUrl = data["avatarUrl"] ?? "";
      preferredContact = data["preferredContact"] ?? "Email";
    }

    setState(() => loading = false);
  }

  Future<void> pickAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => newAvatar = picked);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => saving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      String finalAvatarUrl = avatarUrl;

      if (newAvatar != null) {
        if (kIsWeb && avatarUrl.isNotEmpty && avatarUrl.startsWith('http')) {
          await _imageService.deleteImage(avatarUrl);
        }
        
        finalAvatarUrl = await _imageService.saveImage(newAvatar!, 'avatars');
      }

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .update({
        "name": nameCtrl.text.trim(),
        "phone": phoneCtrl.text.trim(),
        "preferredContact": preferredContact,
        "avatarUrl": finalAvatarUrl,
      });

      setState(() {
        saving = false;
        editing = false;
        avatarUrl = finalAvatarUrl;
        newAvatar = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile updated successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => saving = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating profile: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildAvatar() {
    if (kIsWeb) {
      if (newAvatar != null) {
        return FutureBuilder<Uint8List>(
          future: newAvatar!.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return CircleAvatar(
                radius: 60,
                backgroundImage: MemoryImage(snapshot.data!),
              );
            }
            return CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey.shade300,
              child: const CircularProgressIndicator(),
            );
          },
        );
      } else if (avatarUrl.isNotEmpty && avatarUrl.startsWith('http')) {
        return CircleAvatar(
          radius: 60,
          backgroundImage: NetworkImage(avatarUrl),
          backgroundColor: Colors.grey.shade300,
        );
      } else {
        return CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey.shade300,
          backgroundImage: const AssetImage("assets/default_avatar.jpg"),
        );
      }
    } else {
      if (newAvatar != null) {
        return CircleAvatar(
          radius: 60,
          backgroundImage: FileImage(File(newAvatar!.path)),
        );
      } else if (avatarUrl.isNotEmpty) {
        if (avatarUrl.startsWith('http')) {
          return CircleAvatar(
            radius: 60,
            backgroundImage: NetworkImage(avatarUrl),
            backgroundColor: Colors.grey.shade300,
          );
        } else if (File(avatarUrl).existsSync()) {
          return CircleAvatar(
            radius: 60,
            backgroundImage: FileImage(File(avatarUrl)),
          );
        }
      }
      return CircleAvatar(
        radius: 60,
        backgroundColor: Colors.grey.shade300,
        backgroundImage: const AssetImage("assets/default_avatar.jpg"),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profile")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        centerTitle: true,
        actions: [
          if (!editing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => editing = true),
              tooltip: "Edit Profile",
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: editing ? pickAvatar : null,
                child: Stack(
                  children: [
                    _buildAvatar(),
                    if (editing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: role == "admin" ? Colors.blue.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: role == "admin" ? Colors.blue : Colors.green,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      role == "admin" ? Icons.admin_panel_settings : Icons.person,
                      color: role == "admin" ? Colors.blue : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      role.toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: role == "admin" ? Colors.blue : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              TextFormField(
                controller: nameCtrl,
                enabled: editing,
                decoration: InputDecoration(
                  labelText: "Full Name",
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (v) => v!.isEmpty ? "Name is required" : null,
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: emailCtrl,
                enabled: false,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: phoneCtrl,
                enabled: editing,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Phone is required";
                  if (v.length < 8) return "Phone number too short";
                  return null;
                },
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: userIdCtrl,
                enabled: false,
                decoration: InputDecoration(
                  labelText: "User ID",
                  prefixIcon: const Icon(Icons.badge),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.contact_phone, color: Colors.blue),
                        SizedBox(width: 10),
                        Text(
                          "Preferred Contact Method",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: preferredContact,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: const [
                        DropdownMenuItem(value: "Email", child: Text("Email")),
                        DropdownMenuItem(value: "Phone", child: Text("Phone")),
                        DropdownMenuItem(value: "SMS", child: Text("SMS")),
                        DropdownMenuItem(value: "WhatsApp", child: Text("WhatsApp")),
                      ],
                      onChanged: editing
                          ? (v) => setState(() => preferredContact = v!)
                          : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              if (editing)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: saving
                            ? null
                            : () {
                                setState(() {
                                  editing = false;
                                  newAvatar = null;
                                });
                                _loadUserData();
                              },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(15),
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: saving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(15),
                          backgroundColor: Colors.green,
                        ),
                        child: saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Save Changes",
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 20),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 10),
                          Text(
                            "Account Information",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      _infoRow(Icons.person_outline, "Role", role.toUpperCase()),
                      _infoRow(Icons.contact_phone, "Preferred Contact",
                          preferredContact),
                      _infoRow(Icons.verified_user, "Account Status", "Active"),
                    ],
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 10),
          Text(
            "$label:",
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    userIdCtrl.dispose();
    super.dispose();
  }
}
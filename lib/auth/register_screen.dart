import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import 'auth_service.dart';
import '../constants/defaults.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  String role = "renter";
  bool loading = false;
  File? avatarImage;

  final auth = AuthService();

  // ----------------------------------------------------------
  // PICK AVATAR
  // ----------------------------------------------------------
  Future<void> pickAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() => avatarImage = File(picked.path));
    }
  }

  // ----------------------------------------------------------
  // COMPRESS + SAVE LOCALLY
  // ----------------------------------------------------------
  Future<String> saveAvatarLocal(File file) async {
    final dir = await getApplicationDocumentsDirectory();
    final avatarDir = Directory("${dir.path}/avatars");

    if (!avatarDir.existsSync()) {
      avatarDir.createSync(recursive: true);
    }

    final outputPath =
        "${avatarDir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg";

    final compressed = await FlutterImageCompress.compressAndGetFile(
      file.path,
      outputPath,
      quality: 70,
    );

    return compressed?.path ?? "";
  }

  // ----------------------------------------------------------
  // REGISTER USER
  // ----------------------------------------------------------
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    // Save avatar (optional)
    String avatarUrl = "";
    if (avatarImage != null) {
      avatarUrl = await saveAvatarLocal(avatarImage!);
    }

    final error = await auth.register(
      name: nameCtrl.text.trim(),
      email: emailCtrl.text.trim(),
      password: passCtrl.text.trim(),
      phone: phoneCtrl.text.trim(),
      role: role,
      avatarUrl: avatarUrl, // FIXED PARAMETER
    );

    setState(() => loading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  // ----------------------------------------------------------
  // UI
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Full Name"),
                validator: (v) => v!.isEmpty ? "Enter your name" : null,
              ),

              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (v) {
                  if (v == null || !v.contains("@")) return "Enter a valid email";
                  return null;
                },
              ),

              TextFormField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: "Phone Number"),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.isEmpty) return "Enter phone number";
                  if (v.length < 8) return "Number too short";
                  return null;
                },
              ),

              TextFormField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
                validator: (v) =>
                    v!.length < 6 ? "Min 6 characters required" : null,
              ),

              const SizedBox(height: 15),
              const Text("Select Role"),

              DropdownButton<String>(
                value: role,
                items: const [
                  DropdownMenuItem(value: "renter", child: Text("Renter")),
                  DropdownMenuItem(value: "admin", child: Text("Admin")),
                ],
                onChanged: (value) => setState(() => role = value!),
              ),

              const SizedBox(height: 20),
              const Text("Profile Picture (optional)"),

              ElevatedButton(
                onPressed: pickAvatar,
                child: const Text("Choose Avatar"),
              ),

              if (avatarImage != null)
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: CircleAvatar(
                    radius: 45,
                    backgroundImage: FileImage(avatarImage!),
                  ),
                ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: loading ? null : _register,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Create Account"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
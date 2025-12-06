import 'package:care_center_app/screens/admin/admin_home.dart';
import 'package:care_center_app/screens/renter/renter_home.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';
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

  final auth = AuthService();

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final error = await auth.register(
      name: nameCtrl.text.trim(),
      email: emailCtrl.text.trim(),
      password: passCtrl.text.trim(),
      phone: phoneCtrl.text.trim(),
      role: role,
      avatarUrl: '',
    );

    setState(() => loading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      // After successful registration, navigate based on role
      if (role == "admin") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminHome()),  // Redirect to Admin Home
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RenterHome()),  // Redirect to Renter Home
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blueAccent, Colors.purpleAccent],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 5)],
                ),
                child: const Icon(
                  Icons.medical_services,
                  size: 50,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                "Create your account",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),

              const SizedBox(height: 20),

              // Name Field
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? "Enter your name" : null,
              ),

              const SizedBox(height: 20),

              // Email Field
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty || !value.contains('@') ? "Enter a valid email" : null,
              ),

              const SizedBox(height: 20),

              // Phone Field
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Enter phone number";
                  if (value.length < 8) return "Number too short";
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Password Field
              TextFormField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.length < 6 ? "Min 6 characters required" : null,
              ),

              const SizedBox(height: 20),

              // Role Dropdown
              DropdownButtonFormField<String>(
                initialValue: role,
                onChanged: (newRole) => setState(() => role = newRole!),
                items: const [
                  DropdownMenuItem(value: "renter", child: Text("Renter")),
                  DropdownMenuItem(value: "admin", child: Text("Admin")),
                ],
                decoration: const InputDecoration(
                  labelText: "Select Role",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              // Register Button
              ElevatedButton(
                onPressed: loading ? null : _register,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Create Account"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  minimumSize: Size(double.infinity, 50),
                ),
              ),

              const SizedBox(height: 16),

              // Login Link
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text(
                  "Already have an account? Login",
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

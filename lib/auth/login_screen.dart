import 'package:flutter/material.dart';
import 'auth_service.dart';
import '../screens/admin/admin_home.dart';
import '../screens/renter/renter_home.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final auth = AuthService();
  bool loading = false;

  Future<void> _login() async {
    setState(() => loading = true);

    final error = await auth.login(emailCtrl.text.trim(), passCtrl.text.trim());
    setState(() => loading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    // Check user role
    final role = await auth.getUserRole();

    if (role == "admin") {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const AdminHome()));
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const RenterHome()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextFormField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : _login,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Login"),
            ),

            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              child: const Text("Dont have an account? Register"),
            ),
          ],
        ),
      ),
    );
  }
}
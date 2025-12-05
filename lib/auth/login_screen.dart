// lib/auth/enhanced_login_screen.dart
import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../widgets/animated_button.dart';
import '../widgets/slide_in_animation.dart';
import 'auth_service.dart';
import '../screens/admin/admin_home.dart';
import '../screens/renter/renter_home.dart';
import '../screens/guest/guest_home.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _EnhancedLoginScreenState();
}

class _EnhancedLoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final auth = AuthService();
  bool loading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (emailCtrl.text.trim().isEmpty || passCtrl.text.trim().isEmpty) {
      _showSnackBar("Please enter email and password", AppTheme.warningColor);
      return;
    }

    setState(() => loading = true);

    final error = await auth.login(emailCtrl.text.trim(), passCtrl.text.trim());
    setState(() => loading = false);

    if (error != null) {
      _showSnackBar(error, AppTheme.errorColor);
      return;
    }

    final role = await auth.getUserRole();

    if (!mounted) return;

    if (role == "admin") {
      Navigator.pushReplacement(
        context,
        _createRoute(const AdminHome()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        _createRoute(const RenterHome()),
      );
    }
  }

  void _continueAsGuest() {
    Navigator.pushReplacement(
      context,
      _createRoute(const GuestHome()),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == AppTheme.errorColor ? Icons.error_outline : Icons.info_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadiusMedium,
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.05),
              AppTheme.secondaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Logo
                      SlideInAnimation(
                        delay: 0,
                        child: Hero(
                          tag: 'app_logo',
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: AppTheme.elevatedShadow,
                            ),
                            child: const Icon(
                              Icons.medical_services,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // App Title
                      SlideInAnimation(
                        delay: 100,
                        child: ShaderMask(
                          shaderCallback: (bounds) =>
                              AppTheme.primaryGradient.createShader(bounds),
                          child: const Text(
                            "Care Center",
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      SlideInAnimation(
                        delay: 200,
                        child: Text(
                          "Welcome Back",
                          style: AppTheme.bodyLarge.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Login Form
                      SlideInAnimation(
                        delay: 300,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppTheme.borderRadiusLarge,
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: Column(
                            children: [
                              // Email Field
                              TextField(
                                controller: emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: "Email",
                                  hintText: "Enter your email",
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: AppTheme.borderRadiusMedium,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Password Field
                              TextField(
                                controller: passCtrl,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: "Password",
                                  hintText: "Enter your password",
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: AppTheme.borderRadiusMedium,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Login Button
                              AnimatedButton(
                                text: "Login",
                                icon: Icons.login,
                                onPressed: loading ? null : _login,
                                isLoading: loading,
                              ),

                              const SizedBox(height: 16),

                              // Register Link
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    _createRoute(const RegisterScreen()),
                                  );
                                },
                                child: Text(
                                  "Don't have an account? Register",
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Divider
                      SlideInAnimation(
                        delay: 400,
                        child: Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: AppTheme.textLight.withOpacity(0.5),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                "OR",
                                style: AppTheme.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: AppTheme.textLight.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Guest Button
                      SlideInAnimation(
                        delay: 500,
                        child: AnimatedButton(
                          text: "Continue as Guest",
                          icon: Icons.person_outline,
                          onPressed: _continueAsGuest,
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.accentColor,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Guest Info
                      SlideInAnimation(
                        delay: 600,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withOpacity(0.1),
                            borderRadius: AppTheme.borderRadiusMedium,
                            border: Border.all(
                              color: AppTheme.accentColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppTheme.accentColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Guest mode: Browse equipment and donate items",
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.accentColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
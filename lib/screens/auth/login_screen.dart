import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_constants.dart';
import '../../services/supabase_service.dart';
import '../farmer/farmer_dashboard.dart';
import '../buyer/buyer_home_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey      = GlobalKey<FormState>();
  final _service      = SupabaseService();

  bool _isLoading = false;
  bool _obscure   = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await _service.signIn(
        _emailCtrl.text.trim(),
        _passwordCtrl.text.trim(),
      );
      final userId = response.user?.id;
      if (userId == null) return;

      // users TABLE থেকে role নেওয়া হচ্ছে
      final profile  = await _service.getUserProfile(userId);
      final userRole = profile?['role'] ?? UserRole.buyer;

      if (mounted) _navigateByRole(userRole);
    } on AuthException catch (e) {
      if (mounted) context.showErrorSnackBar(message: e.message);
    } catch (_) {
      if (mounted) context.showErrorSnackBar(message: unexpectedErrorMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateByRole(String role) {
    Widget screen;
    switch (role) {
      case UserRole.farmer:
        screen = const FarmerDashboard();
        break;
      case UserRole.admin:
        screen = const AdminDashboardScreen();
        break;
      default:
        screen = const BuyerHomeScreen();
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width:  double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
            begin: Alignment.topLeft,
            end:   Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(children: [

                const SizedBox(height: 48),

                // ── Logo ──
                Image.asset(
                  'assets/images/logo.png',
                  width: 260,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Column(children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.eco_rounded, size: 64, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    const Text('agridirect+',
                        style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  ]),
                ),

                const SizedBox(height: 8),
                const Text('কৃষক ও ক্রেতার সরাসরি সংযোগ',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),

                const SizedBox(height: 36),

                // ── Form Card ──
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color:        Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(24),
                        border:       Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Column(children: [

                        // Email
                        _buildField(
                          controller:   _emailCtrl,
                          hint:         'ইমেইল ঠিকানা',
                          icon:         Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'ইমেইল দিন';
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                              return 'সঠিক ইমেইল দিন';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        // Password
                        _buildField(
                          controller: _passwordCtrl,
                          hint:       'পাসওয়ার্ড',
                          icon:       Icons.lock_outline_rounded,
                          obscure:    _obscure,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'পাসওয়ার্ড দিন';
                            return null;
                          },
                          suffix: IconButton(
                            icon: Icon(
                              _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Colors.white60, size: 18,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Login Button
                        SizedBox(
                          width:  double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('লগইন করুন',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Go to Register
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            ),
                            child: const Text(
                              'নতুন অ্যাকাউন্ট তৈরি করুন',
                              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    return TextFormField(
      controller:   controller,
      obscureText:  obscure,
      keyboardType: keyboardType,
      style:        const TextStyle(color: Colors.white),
      validator:    validator,
      decoration: InputDecoration(
        hintText:    hint,
        hintStyle:   const TextStyle(color: Colors.white60),
        prefixIcon:  Icon(icon, color: Colors.white70, size: 20),
        suffixIcon:  suffix,
        filled:      true,
        fillColor:   Colors.white.withValues(alpha: 0.1),
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white, width: 1.5)),
        errorBorder:   OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent)),
        errorStyle:    const TextStyle(color: Colors.redAccent),
      ),
    );
  }
}
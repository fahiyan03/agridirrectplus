import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_constants.dart';
import '../../services/supabase_service.dart';
import '../../widgets/password_strength_indicator.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _service = SupabaseService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _role = 'buyer';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── LOGIC LAYER ──

  int _calculateStrengthScore(String password) {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password) && RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password) || RegExp(r'[!@#\$&*~]').hasMatch(password)) score++;
    return score;
  }

  String _getStrengthHint(String password) {
    if (password.length < 8) return 'কমপক্ষে ৮ অক্ষরের পাসওয়ার্ড দিন';
    if (!RegExp(r'[A-Z]').hasMatch(password)) return 'অন্তত একটি বড় হাতের অক্ষর দিন';
    if (!RegExp(r'[a-z]').hasMatch(password)) return 'অন্তত একটি ছোট হাতের অক্ষর দিন';
    if (!RegExp(r'[0-9]').hasMatch(password) && !RegExp(r'[!@#\$&*~]').hasMatch(password)) {
      return 'সংখ্যা বা বিশেষ চিহ্ন ব্যবহার করুন';
    }
    return 'পাসওয়ার্ডটি পর্যাপ্ত শক্তিশালী নয়';
  }

  Future<void> _register() async {
    // ফরম ভ্যালিডেশন চেক
    if (!_formKey.currentState!.validate()) return;

    // পাসওয়ার্ড স্ট্রেন্থ চেক (বিকল্প নিরাপত্তা)
    if (_calculateStrengthScore(_passwordCtrl.text) < 2) {
      context.showErrorSnackBar(message: _getStrengthHint(_passwordCtrl.text));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _service.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        fullName: _nameCtrl.text.trim(),
        role: _role,
        phone: _phoneCtrl.text.trim(),
      );

      if (mounted) {
        context.showSuccessSnackBar(message: 'অ্যাকাউন্ট তৈরি হয়েছে! ইমেইল ভেরিফাই করুন।');
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      if (mounted) context.showErrorSnackBar(message: e.message);
    } catch (_) {
      if (mounted) context.showErrorSnackBar(message: unexpectedErrorMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── UI LAYER ──

  @override
  Widget build(BuildContext context) {
    final int currentStrength = _calculateStrengthScore(_passwordCtrl.text);
    final bool passwordsMatch = _passwordCtrl.text == _confirmCtrl.text && _passwordCtrl.text.isNotEmpty;

    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(children: [
                const SizedBox(height: 32),
                Image.asset('assets/images/logo.png', width: 180),
                const SizedBox(height: 8),
                const Text('নতুন অ্যাকাউন্ট তৈরি করুন',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Column(children: [
                        _buildField(
                          controller: _nameCtrl,
                          hint: 'পুরো নাম *',
                          icon: Icons.person_outline,
                          validator: (v) => (v?.trim().isEmpty ?? true) ? 'আপনার নাম লিখুন' : null,
                        ),
                        const SizedBox(height: 10),
                        _buildField(
                          controller: _phoneCtrl,
                          hint: 'ফোন নম্বর *',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            final val = v?.trim() ?? '';
                            if (val.isEmpty) return 'ফোন নম্বর দিন';
                            if (!RegExp(r'^\d{11}$').hasMatch(val)) return 'সঠিক ১১ ডিজিট নম্বর দিন';
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        _buildRoleDropdown(),
                        const SizedBox(height: 10),
                        _buildField(
                          controller: _emailCtrl,
                          hint: 'ইমেইল ঠিকানা *',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            final val = v?.trim() ?? '';
                            if (val.isEmpty) return 'ইমেইল দিন';
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(val)) return 'সঠিক ইমেইল দিন';
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        _buildField(
                          controller: _passwordCtrl,
                          hint: 'পাসওয়ার্ড *',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscurePassword,
                          onChanged: (_) => setState(() {}),
                          // আপডেট করা ভ্যালিডেটর যা app_constants থেকে আসছে
                          validator: validatePassword,
                          suffix: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white60, size: 18),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        PasswordStrengthIndicator(password: _passwordCtrl.text),
                        const SizedBox(height: 10),
                        _buildField(
                          controller: _confirmCtrl,
                          hint: 'পাসওয়ার্ড নিশ্চিত করুন *',
                          icon: Icons.lock_reset_rounded,
                          obscure: _obscureConfirm,
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'পাসওয়ার্ডটি এখানেও লিখুন';
                            if (v != _passwordCtrl.text) return 'পাসওয়ার্ড মেলেনি';
                            return null;
                          },
                          suffix: IconButton(
                            icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white60, size: 18),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: (_isLoading || currentStrength < 2 || !passwordsMatch) ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF9800),
                              disabledBackgroundColor: Colors.white.withOpacity(0.2),
                              disabledForegroundColor: Colors.white38,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                                : const Text('অ্যাকাউন্ট তৈরি করুন',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: RichText(
                            text: const TextSpan(
                              text: 'ইতিমধ্যে অ্যাকাউন্ট আছে? ',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                              children: [
                                TextSpan(
                                  text: 'লগইন করুন',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _role,
          dropdownColor: const Color(0xFF2E7D32),
          style: const TextStyle(color: Colors.white),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'buyer', child: Text('ক্রেতা (Buyer)')),
            DropdownMenuItem(value: 'farmer', child: Text('কৃষক (Farmer)')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _role = v);
          },
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
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: Colors.white70, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        errorStyle: const TextStyle(color: Colors.orangeAccent),
      ),
    );
  }
}
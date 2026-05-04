import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthProvider>().profile;
    _nameCtrl.text = profile?['full_name'] ?? '';
    _phoneCtrl.text = profile?['phone'] ?? '';
    _addressCtrl.text = profile?['address'] ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  // FIX: image upload এর পর profile reload করা হচ্ছে সঠিকভাবে
  // আগে `await context.read<AuthProvider>().profile` ছিল
  // এটা Future না, getter — await করলে কিছু হয় না, profile reload হত না
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked =
    await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked == null) return;

    if (mounted) setState(() => _isUploadingImage = true);

    try {
      final url =
      await SupabaseService().uploadImage(File(picked.path), 'profiles');
      if (url != null) {
        await SupabaseService().updateProfileImage(url);
        // FIX: getter এর বদলে actual reload method call করো
        if (mounted) await context.read<AuthProvider>().refreshProfile();
        if (mounted) context.showSuccessSnackBar(message: 'ছবি আপডেট হয়েছে');
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar(message: e.toString());
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await SupabaseService().updateProfile({
        'full_name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
      });
      // FIX: save এর পর profile reload করো
      if (mounted) await context.read<AuthProvider>().refreshProfile();
      if (mounted) {
        setState(() => _isEditing = false);
        context.showSuccessSnackBar(message: 'প্রোফাইল আপডেট হয়েছে');
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar(message: e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // FIX: null/empty safe initial — এটাই মূল crash এর কারণ ছিল
  // full_name = '' হলে ''[0] = RangeError
  String _getInitial(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return '?';
    return fullName.trim()[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;
    final role = auth.role;

    // FIX: null-safe name ও initial
    final fullName = profile?['full_name']?.toString() ?? '';
    final initial = _getInitial(fullName);
    final profileImageUrl = profile?['profile_image_url']?.toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('প্রোফাইল'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: const Text('সেভ করুন',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(children: [

          // ── Header ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(children: [

              // Profile Image
              GestureDetector(
                onTap: _isUploadingImage ? null : _pickAndUploadImage,
                child: Stack(children: [
                  CircleAvatar(
                    radius: 40,
                    // FIX: withOpacity → withValues
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    backgroundImage: profileImageUrl != null
                        ? NetworkImage(profileImageUrl)
                        : null,
                    child: profileImageUrl == null
                        ? _isUploadingImage
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                    // FIX: _getInitial() — empty string crash আর হবে না
                        : Text(initial,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold))
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                          color: AppColors.accent, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt_rounded,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 10),

              // FIX: empty name হলে '-' দেখাও, crash করবে না
              Text(
                fullName.isNotEmpty ? fullName : '-',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),

              Container(
                margin: const EdgeInsets.only(top: 4),
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                decoration: BoxDecoration(
                  // FIX: withOpacity → withValues
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  role == UserRole.farmer
                      ? 'কৃষক'
                      : role == UserRole.admin
                      ? 'অ্যাডমিন'
                      : 'ক্রেতা',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ]),
          ),

          Padding(
            padding: pagePadding,
            child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              const SizedBox(height: 16),

              // ── Info Card ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  _buildField('পুরো নাম', _nameCtrl,
                      Icons.person_outline_rounded),
                  const Divider(height: 20),
                  _buildField('ফোন নম্বর', _phoneCtrl, Icons.phone_outlined,
                      type: TextInputType.phone),
                  const Divider(height: 20),
                  _buildField('ঠিকানা', _addressCtrl,
                      Icons.location_on_outlined,
                      maxLines: 2),
                ]),
              ),

              const SizedBox(height: 16),

              // ── Email (Read Only) ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.email_outlined,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ইমেইল',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                          // FIX: null-safe email
                          Text(auth.user?.email ?? '-',
                              style: const TextStyle(fontSize: 14)),
                        ]),
                  ),
                  const Text('পরিবর্তন করা যাবে না',
                      style: TextStyle(
                          fontSize: 10, color: AppColors.textHint)),
                ]),
              ),

              const SizedBox(height: 24),

              // ── Logout ──
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await auth.signOut();
                    if (context.mounted) {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()));
                    }
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('লগআউট করুন'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error)),
                ),
              ),

              const SizedBox(height: 16),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildField(
      String label,
      TextEditingController ctrl,
      IconData icon, {
        TextInputType? type,
        int maxLines = 1,
      }) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: AppColors.primary, size: 18),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          _isEditing
              ? TextFormField(
            controller: ctrl,
            keyboardType: type,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(
                isDense: true,
                contentPadding:
                EdgeInsets.symmetric(vertical: 4)),
          )
          // FIX: empty text হলে '-' দেখাও
              : Text(
            ctrl.text.isNotEmpty ? ctrl.text : '-',
            style: const TextStyle(fontSize: 14),
          ),
        ]),
      ),
    ]);
  }
}
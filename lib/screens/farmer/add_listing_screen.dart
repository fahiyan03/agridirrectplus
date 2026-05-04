import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/product_provider.dart';
import '../../services/supabase_service.dart';

class AddListingScreen extends StatefulWidget {
  const AddListingScreen({super.key});
  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  File? _imageFile;
  String _unit = 'কেজি';
  int _zone = 1;
  String _category = 'সবজি';
  bool _isLoading = false;

  // GPS variables
  double? _latitude;
  double? _longitude;

  final List<String> _units = ['কেজি', 'গ্রাম', 'লিটার', 'পিস', 'ডজন', 'মণ'];
  final Map<int, List<String>> _zoneCategories = {
    1: ['সবজি', 'মাছ', 'দুধ', 'ডিম', 'ফুল'],
    2: ['ফল', 'মুরগি', 'মৌসুমি সবজি'],
    3: ['চাল', 'আলু', 'পেঁয়াজ', 'রসুন', 'গম'],
    4: ['শুকনো মরিচ', 'মশলা', 'চিংড়ি', 'হলুদ', 'আদা'],
  };

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
    await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // image upload আলাদা try-catch — upload fail হলেও listing তৈরি হবে
      String? imageUrl;
      if (_imageFile != null) {
        try {
          imageUrl =
          await SupabaseService().uploadImage(_imageFile!, 'products');
        } catch (_) {
          // image upload fail হলে imageUrl = null, listing চলবে
        }
      }

      final success = await context.read<ProductProvider>().createProduct(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: double.parse(_priceCtrl.text.trim()),
        category: _category,
        zone: _zone,
        quantity: double.parse(_qtyCtrl.text.trim()),
        unit: _unit,
        imageUrl: imageUrl,
        // GPS coordinates
        latitude: _latitude,
        longitude: _longitude,
      );

      if (success && mounted) {
        context.showSuccessSnackBar(message: 'লিস্টিং সফলভাবে প্রকাশ হয়েছে!');
        Navigator.pop(context);
      } else if (mounted) {
        context.showErrorSnackBar(message: 'লিস্টিং প্রকাশ করতে সমস্যা হয়েছে');
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar(message: e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _zoneCategories[_zone] ?? ['সবজি'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('নতুন লিস্টিং')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Image Picker ──
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_imageFile!, fit: BoxFit.cover),
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_rounded,
                          size: 48,
                          color:
                          AppColors.primary.withValues(alpha: 0.5)),
                      const SizedBox(height: 8),
                      const Text('ছবি যোগ করুন',
                          style: TextStyle(
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ── GPS Status ──
              Row(children: [
                Icon(
                  _latitude != null
                      ? Icons.location_on_rounded
                      : Icons.location_off_rounded,
                  size: 14,
                  color: _latitude != null
                      ? AppColors.success
                      : AppColors.textHint,
                ),
                const SizedBox(width: 4),
                Text(
                  _latitude != null
                      ? 'অবস্থান পাওয়া গেছে (${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)})'
                      : 'অবস্থান পাওয়া যায়নি — map এ দেখা যাবে না',
                  style: TextStyle(
                    fontSize: 11,
                    color: _latitude != null
                        ? AppColors.success
                        : AppColors.textHint,
                  ),
                ),
              ]),

              const SizedBox(height: 12),

              // ── Title ──
              _buildLabel('পণ্যের নাম *'),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                    hintText: 'যেমন: তাজা আলু, দেশি পেঁয়াজ'),
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'পণ্যের নাম দিন' : null,
              ),

              const SizedBox(height: 12),

              // ── Price & Qty ──
              Row(children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('মূল্য (৳) *'),
                        TextFormField(
                          controller: _priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: '০'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'মূল্য দিন';
                            if (double.tryParse(v) == null)
                              return 'সঠিক মূল্য দিন';
                            return null;
                          },
                        ),
                      ]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('পরিমাণ *'),
                        TextFormField(
                          controller: _qtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: '০'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'পরিমাণ দিন';
                            if (double.tryParse(v) == null)
                              return 'সঠিক পরিমাণ দিন';
                            return null;
                          },
                        ),
                      ]),
                ),
              ]),

              const SizedBox(height: 12),

              // ── Unit ──
              _buildLabel('একক'),
              DropdownButtonFormField<String>(
                value: _unit,
                decoration: const InputDecoration(),
                items: _units
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (v) => setState(() => _unit = v!),
              ),

              const SizedBox(height: 12),

              // ── Zone ──
              _buildLabel('জোন নির্বাচন করুন *'),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    ...zoneConfigs.map((z) => RadioListTile<int>(
                      value: z.zone,
                      groupValue: _zone,
                      activeColor: AppColors.primary,
                      title: Text(z.nameBn,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          '${z.deliveryTimeBn} - ${z.radiusKm == 9999 ? "সারাদেশ" : "${z.radiusKm} কিমি"}',
                          style: const TextStyle(fontSize: 11)),
                      onChanged: (v) => setState(() {
                        _zone = v!;
                        _category = _zoneCategories[_zone]!.first;
                      }),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    )),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Category ──
              _buildLabel('ক্যাটাগরি'),
              DropdownButtonFormField<String>(
                value: categories.contains(_category)
                    ? _category
                    : categories.first,
                decoration: const InputDecoration(),
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),

              const SizedBox(height: 12),

              // ── Description ──
              _buildLabel('বিবরণ'),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    hintText: 'পণ্য সম্পর্কে বিস্তারিত লিখুন...'),
              ),

              const SizedBox(height: 24),

              // ── Submit ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('লিস্টিং প্রকাশ করুন',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textPrimary)),
    );
  }
}
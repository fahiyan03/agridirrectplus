import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/product_provider.dart';
import '../../services/supabase_service.dart';

class EditListingScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  const EditListingScreen({super.key, required this.product});

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _qtyCtrl;
  final _formKey = GlobalKey<FormState>();

  File? _newImageFile;
  late String _unit;
  late int _zone;
  late String _category;
  bool _isLoading = false;

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
    _titleCtrl = TextEditingController(text: widget.product['title'] ?? '');
    _descCtrl = TextEditingController(text: widget.product['description'] ?? '');
    _priceCtrl = TextEditingController(text: '${widget.product['price'] ?? ''}');
    _qtyCtrl = TextEditingController(text: '${widget.product['quantity'] ?? ''}');
    _unit = widget.product['unit'] ?? 'কেজি';
    _zone = widget.product['zone'] ?? 1;
    _category = widget.product['category'] ?? 'সবজি';
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose();
    _priceCtrl.dispose(); _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked != null) setState(() => _newImageFile = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      String? imageUrl = widget.product['image_url'];
      if (_newImageFile != null) {
        imageUrl = await SupabaseService().uploadImage(_newImageFile!, 'products');
      }

      await SupabaseService().updateProduct(
        productId: widget.product['id'],
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: double.parse(_priceCtrl.text.trim()),
        category: _category,
        zone: _zone,
        quantity: double.parse(_qtyCtrl.text.trim()),
        unit: _unit,
        imageUrl: imageUrl,
      );

      await context.read<ProductProvider>().loadMyProducts();

      if (mounted) {
        context.showSuccessSnackBar(message: 'লিস্টিং আপডেট হয়েছে!');
        Navigator.pop(context);
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
    if (!categories.contains(_category)) _category = categories.first;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('লিস্টিং এডিট করুন')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Image ──
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withOpacity(0.3))),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _newImageFile != null
                        ? Image.file(_newImageFile!, fit: BoxFit.cover)
                        : (widget.product['image_url'] != null
                        ? CachedNetworkImage(imageUrl: widget.product['image_url'], fit: BoxFit.cover)
                        : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_photo_alternate_rounded, size: 48, color: AppColors.primary.withOpacity(0.5)),
                      const Text('ছবি পরিবর্তন করুন', style: TextStyle(color: AppColors.textSecondary)),
                    ])),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              _buildLabel('পণ্যের নাম *'),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(hintText: 'পণ্যের নাম'),
                validator: (v) => v == null || v.trim().isEmpty ? 'নাম দিন' : null,
              ),

              const SizedBox(height: 12),

              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildLabel('মূল্য (৳) *'),
                  TextFormField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || double.tryParse(v) == null ? 'সঠিক মূল্য' : null,
                  ),
                ])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildLabel('পরিমাণ *'),
                  TextFormField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || double.tryParse(v) == null ? 'সঠিক পরিমাণ' : null,
                  ),
                ])),
              ]),

              const SizedBox(height: 12),

              _buildLabel('একক'),
              DropdownButtonFormField<String>(
                value: _units.contains(_unit) ? _unit : _units.first,
                decoration: const InputDecoration(),
                items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (v) => setState(() => _unit = v!),
              ),

              const SizedBox(height: 12),

              _buildLabel('জোন'),
              DropdownButtonFormField<int>(
                value: _zone,
                decoration: const InputDecoration(),
                items: zoneConfigs.map((z) => DropdownMenuItem(value: z.zone, child: Text(z.nameBn))).toList(),
                onChanged: (v) => setState(() { _zone = v!; _category = _zoneCategories[_zone]!.first; }),
              ),

              const SizedBox(height: 12),

              _buildLabel('ক্যাটাগরি'),
              DropdownButtonFormField<String>(
                value: categories.contains(_category) ? _category : categories.first,
                decoration: const InputDecoration(),
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),

              const SizedBox(height: 12),

              _buildLabel('বিবরণ'),
              TextFormField(controller: _descCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'বিবরণ...')),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('আপডেট করুন', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
    );
  }
}
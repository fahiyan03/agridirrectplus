import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_constants.dart';
import '../../services/plant_id_service.dart';
import 'crop_doctor_result_screen.dart';

class CropDoctorUploadScreen extends StatefulWidget {
  const CropDoctorUploadScreen({super.key});
  @override
  State<CropDoctorUploadScreen> createState() => _CropDoctorUploadScreenState();
}

class _CropDoctorUploadScreenState extends State<CropDoctorUploadScreen> {
  File? _imageFile;
  bool _isAnalyzing = false;
  final _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _analyze() async {
    if (_imageFile == null) {
      context.showErrorSnackBar(message: 'আগে একটি ছবি নিন');
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final result = await PlantIdService().identifyDisease(_imageFile!);
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => CropDoctorResultScreen(result: result, imageFile: _imageFile!),
        ));
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar(message: e.toString());
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Crop Doctor'),
        backgroundColor: AppColors.primaryDark,
      ),
      body: SingleChildScrollView(
        padding: pagePadding,
        child: Column(children: [

          // ── Header ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primaryDark, AppColors.primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              const Icon(Icons.biotech_rounded, color: Colors.white, size: 36),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('AI ফসল রোগ নির্ণয়', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('ফসলের ছবি তুলুন, AI রোগ শনাক্ত করবে', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ])),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Image Area ──
          GestureDetector(
            onTap: () => _showImageSourceSheet(),
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
              ),
              child: _imageFile != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(_imageFile!, fit: BoxFit.cover),
              )
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_a_photo_rounded, size: 56, color: AppColors.primary.withOpacity(0.4)),
                const SizedBox(height: 12),
                const Text('ছবি তুলুন বা গ্যালারি থেকে নিন', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                const SizedBox(height: 6),
                const Text('ফসলের আক্রান্ত অংশের স্পষ্ট ছবি নিন', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
              ]),
            ),
          ),

          const SizedBox(height: 16),

          // ── Image Source Buttons ──
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('ক্যামেরা'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text('গ্যালারি'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary)),
              ),
            ),
          ]),

          const SizedBox(height: 20),

          // ── Tips ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.accent.withOpacity(0.2))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.lightbulb_outline_rounded, color: AppColors.accent, size: 18),
                SizedBox(width: 6),
                Text('ভালো ফলাফলের জন্য', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent, fontSize: 13)),
              ]),
              const SizedBox(height: 8),
              ...[
                'আক্রান্ত পাতা বা ডালের কাছ থেকে ছবি তুলুন',
                'ছবি যেন ঝাপসা না হয়',
                'ভালো আলোতে ছবি তুলুন',
                'একটি ছবিতে একটি পাতা বা অংশ রাখুন',
              ].map((tip) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [
                  const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Expanded(child: Text(tip, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                ]),
              )),
            ]),
          ),

          const SizedBox(height: 24),

          // ── Analyze Button ──
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: (_imageFile == null || _isAnalyzing) ? null : _analyze,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark),
              icon: _isAnalyzing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.search_rounded),
              label: Text(_isAnalyzing ? 'বিশ্লেষণ করা হচ্ছে...' : 'রোগ শনাক্ত করুন', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),

          const SizedBox(height: 12),

          const Text('* এটি AI-ভিত্তিক পরামর্শ। বিশেষজ্ঞের মতামত নেওয়া সবসময় উত্তম।',
              style: TextStyle(fontSize: 11, color: AppColors.textHint), textAlign: TextAlign.center),

          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
            title: const Text('ক্যামেরা দিয়ে ছবি তুলুন'),
            onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
            title: const Text('গ্যালারি থেকে বেছে নিন'),
            onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
          ),
        ]),
      ),
    );
  }
}
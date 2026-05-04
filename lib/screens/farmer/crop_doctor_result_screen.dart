import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_constants.dart';

class CropDoctorResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;
  final File imageFile;

  const CropDoctorResultScreen(
      {super.key, required this.result, required this.imageFile});

  @override
  Widget build(BuildContext context) {
    final isHealthy = result['is_healthy'] ?? false;
    final diseases = (result['diseases'] as List?) ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Crop Doctor ফলাফল'),
        backgroundColor: AppColors.primaryDark,
      ),
      body: SingleChildScrollView(
        padding: pagePadding,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Analyzed Image ──
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(imageFile,
                height: 200, width: double.infinity, fit: BoxFit.cover),
          ),

          const SizedBox(height: 16),

          // ── Result Banner ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // FIX: withOpacity → withValues
              color: (isHealthy ? AppColors.success : AppColors.error)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: (isHealthy ? AppColors.success : AppColors.error)
                      .withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              Icon(
                  isHealthy
                      ? Icons.check_circle_rounded
                      : Icons.warning_rounded,
                  color: isHealthy ? AppColors.success : AppColors.error,
                  size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          isHealthy
                              ? 'ফসল সুস্থ আছে!'
                              : 'রোগ শনাক্ত হয়েছে',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isHealthy
                                  ? AppColors.success
                                  : AppColors.error)),
                      Text(
                          isHealthy
                              ? 'আপনার ফসলে কোনো রোগের লক্ষণ পাওয়া যায়নি'
                              : '${diseases.length}টি সম্ভাব্য রোগ পাওয়া গেছে',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ]),
              ),
            ]),
          ),

          const SizedBox(height: 16),

          // ── Disease Details ──
          if (!isHealthy && diseases.isNotEmpty) ...[
            const Text('রোগের বিস্তারিত',
                style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            ...diseases.map((disease) =>
                _DiseaseCard(disease: disease as Map<String, dynamic>)),
          ],

          const SizedBox(height: 16),

          // ── Expert Contact ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              // FIX: withOpacity → withValues
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.1)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('বিশেষজ্ঞ পরামর্শ নিন',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.primary)),
              const SizedBox(height: 8),
              const Text('কৃষি বিশেষজ্ঞের সাথে যোগাযোগ করুন:',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => launchUrl(Uri.parse('tel:16123')),
                    icon: const Icon(Icons.phone_rounded, size: 16),
                    label: const Text('কৃষি হেল্পলাইন',
                        style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary)),
                  ),
                ),
              ]),
            ]),
          ),

          const SizedBox(height: 16),

          // ── Disclaimer ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              // FIX: withOpacity → withValues
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppColors.accent, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                      child: Text(
                        'এটি AI-ভিত্তিক প্রাথমিক রোগ নির্ণয়। চূড়ান্ত সিদ্ধান্তের আগে অবশ্যই কৃষি বিশেষজ্ঞের পরামর্শ নিন।',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      )),
                ]),
          ),

          const SizedBox(height: 16),

          // ── Retry Button ──
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('নতুন ছবি বিশ্লেষণ করুন'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary)),
            ),
          ),

          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

class _DiseaseCard extends StatefulWidget {
  final Map<String, dynamic> disease;
  const _DiseaseCard({required this.disease});

  @override
  State<_DiseaseCard> createState() => _DiseaseCardState();
}

class _DiseaseCardState extends State<_DiseaseCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // FIX: Plant.id API থেকে probability double হিসেবে আসে (যেমন 0.847)
    // int.tryParse("0.847") = null → সবসময় 0% দেখাত
    // এখন double parse করে percentage বানানো হচ্ছে
    final raw = widget.disease['probability'];
    final probability = ((raw is num
        ? raw.toDouble()
        : double.tryParse(raw?.toString() ?? '') ?? 0.0) *
        100)
        .round();

    final color = probability > 70
        ? AppColors.error
        : probability > 40
        ? AppColors.warning
        : AppColors.info;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // FIX: withOpacity → withValues
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        ListTile(
          leading: CircleAvatar(
            // FIX: withOpacity → withValues
            backgroundColor: color.withValues(alpha: 0.1),
            child: Text('$probability%',
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
          title: Text(widget.disease['name']?.toString() ?? '',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: widget.disease['common_names']?.isNotEmpty == true
              ? Text(widget.disease['common_names'].toString(),
              style: const TextStyle(fontSize: 11))
              : null,
          trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more,
              color: AppColors.textSecondary),
          onTap: () => setState(() => _expanded = !_expanded),
        ),

        if (_expanded) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (widget.disease['treatment_chemical']?.isNotEmpty == true) ...[
                _TreatmentSection(
                    title: 'রাসায়নিক চিকিৎসা',
                    icon: Icons.science_rounded,
                    color: AppColors.error,
                    text: widget.disease['treatment_chemical'].toString()),
                const SizedBox(height: 8),
              ],
              if (widget.disease['treatment_biological']?.isNotEmpty ==
                  true) ...[
                _TreatmentSection(
                    title: 'জৈব প্রতিকার',
                    icon: Icons.eco_rounded,
                    color: AppColors.success,
                    text: widget.disease['treatment_biological'].toString()),
                const SizedBox(height: 8),
              ],
              if (widget.disease['treatment_prevention']?.isNotEmpty == true)
                _TreatmentSection(
                    title: 'প্রতিরোধ',
                    icon: Icons.shield_rounded,
                    color: AppColors.info,
                    text: widget.disease['treatment_prevention'].toString()),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _TreatmentSection extends StatelessWidget {
  final String title, text;
  final IconData icon;
  final Color color;
  const _TreatmentSection(
      {required this.title,
        required this.text,
        required this.icon,
        required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        // FIX: withOpacity → withValues
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 12, color: color)),
            const SizedBox(height: 4),
            Text(text,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ),
      ]),
    );
  }
}
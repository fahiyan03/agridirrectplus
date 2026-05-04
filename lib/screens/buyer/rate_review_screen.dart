import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_constants.dart';

class RateReviewScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const RateReviewScreen({super.key, required this.order});

  @override
  State<RateReviewScreen> createState() => _RateReviewScreenState();
}

class _RateReviewScreenState extends State<RateReviewScreen> {
  final _supabase = Supabase.instance.client;
  final _commentCtrl = TextEditingController();
  int _rating = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      context.showErrorSnackBar(message: 'রেটিং দিন');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // আগে review দেওয়া হয়েছে কিনা চেক করো
      final existing = await _supabase
          .from('reviews')
          .select()
          .eq('order_id', widget.order['id'])
          .maybeSingle();

      if (existing != null) {
        if (mounted) {
          context.showErrorSnackBar(message: 'এই অর্ডারে আগেই রিভিউ দেওয়া হয়েছে');
          Navigator.pop(context);
        }
        return;
      }

      await _supabase.from('reviews').insert({
        'buyer_id': userId,
        'farmer_id': widget.order['farmer_id'],
        'order_id': widget.order['id'],
        'rating': _rating,
        'comment': _commentCtrl.text.trim().isNotEmpty ? _commentCtrl.text.trim() : null,
      });

      if (mounted) {
        context.showSuccessSnackBar(message: 'রিভিউ দেওয়া হয়েছে, ধন্যবাদ!');
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('রিভিউ দিন')),
      body: SingleChildScrollView(
        padding: pagePadding,
        child: Column(children: [

          const SizedBox(height: 20),

          // ── Farmer Avatar ──
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
            child: Text(
              (widget.order['farmer']?['full_name'] ?? 'ক')[0].toUpperCase(),
              style: const TextStyle(color: AppColors.primary, fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          Text(widget.order['farmer']?['full_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(widget.order['product']?['title'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),

          const SizedBox(height: 24),

          // ── Star Rating ──
          const Text('আপনার অভিজ্ঞতা কেমন ছিল?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ...List.generate(5, (i) => GestureDetector(
              onTap: () => setState(() => _rating = i + 1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  i < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: AppColors.accent,
                  size: 40,
                ),
              ),
            )),
          ]),
          const SizedBox(height: 8),
          Text(
            _rating == 0 ? 'রেটিং দিতে তারা চাপুন' : ['', 'খুব খারাপ', 'খারাপ', 'ঠিক আছে', 'ভালো', 'চমৎকার'][_rating],
            style: TextStyle(color: _rating == 0 ? AppColors.textHint : AppColors.accent, fontSize: 14, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 20),

          // ── Comment ──
          TextFormField(
            controller: _commentCtrl,
            maxLines: 4,
            maxLength: 300,
            decoration: const InputDecoration(
              hintText: 'আপনার অভিজ্ঞতা লিখুন (ঐচ্ছিক)...',
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 24),

          // ── Submit ──
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('রিভিউ জমা দিন', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),

          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}
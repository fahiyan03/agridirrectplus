import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewService {
  final _supabase = Supabase.instance.client;

  // ── Submit Review ─────────────────────────────────────────

  Future<void> submitReview({
    required String farmerId,
    required String orderId,
    required int rating,
    String? comment,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('লগইন করুন');

    // আগে review দেওয়া হয়েছে কিনা চেক করো
    final existing = await _supabase
        .from('reviews')
        .select()
        .eq('order_id', orderId)
        .maybeSingle();

    if (existing != null) throw Exception('এই অর্ডারে আগেই রিভিউ দেওয়া হয়েছে');

    await _supabase.from('reviews').insert({
      'buyer_id':  userId,
      'farmer_id': farmerId,
      'order_id':  orderId,
      'rating':    rating,
      'comment':   comment?.trim().isEmpty == true ? null : comment?.trim(),
    });
  }

  // ── Get Farmer Reviews ────────────────────────────────────

  Future<List<Map<String, dynamic>>> getFarmerReviews(String farmerId) async {
    final data = await _supabase
        .from('reviews')
        .select('*, buyer:users!reviews_buyer_id_fkey(full_name, profile_image_url)')
        .eq('farmer_id', farmerId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  // ── Get Average Rating ────────────────────────────────────

  Future<double> getAverageRating(String farmerId) async {
    final reviews = await getFarmerReviews(farmerId);
    if (reviews.isEmpty) return 0.0;

    final total = reviews.fold(0, (sum, r) => sum + ((r['rating'] ?? 0) as int));
    return total / reviews.length;
  }

  // ── Check Already Reviewed ───────────────────────────────

  Future<bool> hasReviewed(String orderId) async {
    final data = await _supabase
        .from('reviews')
        .select()
        .eq('order_id', orderId)
        .maybeSingle();
    return data != null;
  }
}
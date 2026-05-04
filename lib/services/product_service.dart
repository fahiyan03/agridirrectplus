import 'package:supabase_flutter/supabase_flutter.dart';

class ProductService {
  final _supabase = Supabase.instance.client;

  // ── Get All Products ──────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAllProducts({int? zone}) async {
    var q = _supabase
        .from('products')
        .select('*, farmer:users!products_farmer_id_fkey(full_name, profile_image_url, address)')
        .eq('is_available', true);

    if (zone != null) q = q.eq('zone', zone);

    final data = await q.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  // ── Get My Products (Farmer) ──────────────────────────────

  Future<List<Map<String, dynamic>>> getMyProducts() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _supabase
        .from('products')
        .select('*')
        .eq('farmer_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  // ── Get Single Product ────────────────────────────────────

  Future<Map<String, dynamic>?> getProduct(String productId) async {
    return await _supabase
        .from('products')
        .select('*, farmer:users!products_farmer_id_fkey(full_name, profile_image_url, address, phone)')
        .eq('id', productId)
        .maybeSingle();
  }

  // ── Create Product ────────────────────────────────────────

  Future<void> createProduct({
    required String title,
    required String description,
    required double price,
    required String category,
    required int zone,
    required double quantity,
    required String unit,
    String? imageUrl,
    double? latitude,
    double? longitude,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('লগইন করুন');

    await _supabase.from('products').insert({
      'farmer_id':   userId,
      'title':       title,
      'description': description,
      'price':       price,
      'category':    category,
      'zone':        zone,
      'quantity':    quantity,
      'unit':        unit,
      'image_url':   imageUrl,
      'latitude':    latitude,
      'longitude':   longitude,
      'is_available': true,
    });
  }

  // ── Update Product ────────────────────────────────────────

  Future<void> updateProduct({
    required String productId,
    required String title,
    required String description,
    required double price,
    required String category,
    required int zone,
    required double quantity,
    required String unit,
    String? imageUrl,
  }) async {
    await _supabase.from('products').update({
      'title':       title,
      'description': description,
      'price':       price,
      'category':    category,
      'zone':        zone,
      'quantity':    quantity,
      'unit':        unit,
      'image_url':   imageUrl,
    }).eq('id', productId);
  }

  // ── Delete Product ────────────────────────────────────────

  Future<void> deleteProduct(String productId) async {
    await _supabase.from('products').delete().eq('id', productId);
  }

  // ── Toggle Availability ───────────────────────────────────

  Future<void> toggleAvailability(String productId, bool current) async {
    await _supabase
        .from('products')
        .update({'is_available': !current})
        .eq('id', productId);
  }

  // ── Search Products ───────────────────────────────────────

  Future<List<Map<String, dynamic>>> searchProducts({
    required String query,
    int? zone,
    String? category,
    double? maxPrice,
  }) async {
    var q = _supabase
        .from('products')
        .select('*, farmer:users!products_farmer_id_fkey(full_name, address)')
        .eq('is_available', true);

    if (query.isNotEmpty)    q = q.ilike('title', '%$query%');
    if (zone != null)        q = q.eq('zone', zone);
    if (category != null)    q = q.eq('category', category);
    if (maxPrice != null)    q = q.lte('price', maxPrice);

    final data = await q.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  // ── Watchlist ─────────────────────────────────────────────

  Future<void> addToWatchlist(String productId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase.from('watchlist').insert({
      'user_id':    userId,
      'product_id': productId,
    });
  }

  Future<void> removeFromWatchlist(String productId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase
        .from('watchlist')
        .delete()
        .eq('user_id', userId)
        .eq('product_id', productId);
  }

  Future<bool> isWatchlisted(String productId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;
    final data = await _supabase
        .from('watchlist')
        .select()
        .eq('user_id', userId)
        .eq('product_id', productId)
        .maybeSingle();
    return data != null;
  }

  Future<List<Map<String, dynamic>>> getWatchlist() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await _supabase
        .from('watchlist')
        .select('*, product:products(*, farmer:users!products_farmer_id_fkey(full_name))')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }
}
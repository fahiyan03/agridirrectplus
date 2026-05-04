import 'package:supabase_flutter/supabase_flutter.dart';

class OrderService {
  final _supabase = Supabase.instance.client;

  // ── Place Order (Buyer) ───────────────────────────────────

  Future<void> createOrder({
    required String productId,
    required String farmerId,
    required double quantity,
    required double totalPrice,
    String? deliveryAddress,
    String? notes,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('লগইন করুন');

    await _supabase.from('orders').insert({
      'buyer_id':        userId,
      'product_id':      productId,
      'farmer_id':       farmerId,
      'quantity':        quantity,
      'total_price':     totalPrice,
      'status':          'pending',
      'delivery_address': deliveryAddress,
      'notes':           notes,
    });
  }

  // ── My Orders (Buyer) ─────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMyOrdersAsBuyer() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _supabase
        .from('orders')
        .select('*, product:products(title, unit, price, image_url), farmer:users!orders_farmer_id_fkey(full_name, phone)')
        .eq('buyer_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  // ── Incoming Orders (Farmer) ──────────────────────────────

  Future<List<Map<String, dynamic>>> getIncomingOrdersAsFarmer() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _supabase
        .from('orders')
        .select('*, product:products(title, unit, price), buyer:users!orders_buyer_id_fkey(full_name, phone)')
        .eq('farmer_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  // ── Update Order Status ───────────────────────────────────

  Future<void> updateStatus(String orderId, String status) async {
    await _supabase
        .from('orders')
        .update({'status': status})
        .eq('id', orderId);
  }

  // ── Get Single Order ──────────────────────────────────────

  Future<Map<String, dynamic>?> getOrder(String orderId) async {
    return await _supabase
        .from('orders')
        .select('*, product:products(title, unit, price, image_url), buyer:users!orders_buyer_id_fkey(full_name, phone, address), farmer:users!orders_farmer_id_fkey(full_name, phone)')
        .eq('id', orderId)
        .maybeSingle();
  }

  // ── Cancel Order (Buyer) ──────────────────────────────────

  Future<void> cancelOrder(String orderId) async {
    await updateStatus(orderId, 'cancelled');
  }

  // ── Accept Order (Farmer) ─────────────────────────────────

  Future<void> acceptOrder(String orderId) async {
    await updateStatus(orderId, 'accepted');
  }

  // ── Reject Order (Farmer) ─────────────────────────────────

  Future<void> rejectOrder(String orderId) async {
    await updateStatus(orderId, 'rejected');
  }

  // ── Deliver Order (Farmer) ────────────────────────────────

  Future<void> deliverOrder(String orderId) async {
    await updateStatus(orderId, 'delivered');
  }

  // ── All Orders (Admin) ────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAllOrders({int limit = 20}) async {
    final data = await _supabase
        .from('orders')
        .select('*, product:products(title), buyer:users!orders_buyer_id_fkey(full_name)')
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(data);
  }
}
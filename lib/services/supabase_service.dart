import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

// StudentMarketPlace-এর supabase_service.dart থেকে adapted
// পরিবর্তন: posts → products, profiles → users (role-based), favorites → watchlist

class SupabaseService {
  final supabase = Supabase.instance.client;

  // ─── AUTH ────────────────────────────────────────────────────

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role, // 'farmer' | 'buyer' | 'admin'
    String? phone,
    String? address,
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': role,
        'phone': phone,
        'address': address,
      },
    );
    return response;
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  User? get currentUser => supabase.auth.currentUser;

  // ─── PROFILE ─────────────────────────────────────────────────

  // StudentMarketPlace-এর _ensureUserProfileExists থেকে adapted
  Future<void> ensureUserProfileExists(User user) async {
    final existing = await supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (existing == null) {
      await supabase.from('users').insert({
        'id': user.id,
        'full_name': user.userMetadata?['full_name'] ?? 'AgriDirect User',
        'email': user.email,
        'role': user.userMetadata?['role'] ?? 'buyer',
        'phone': user.userMetadata?['phone'],
        'address': user.userMetadata?['address'],
      });
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    return await supabase
        .from('users')
        .select('*')
        .eq('id', userId)
        .maybeSingle();
  }

  Future<void> updateProfileImage(String imageUrl) async {
    final user = currentUser;
    if (user == null) return;
    await supabase
        .from('users')
        .update({'profile_image_url': imageUrl}).eq('id', user.id);
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final user = currentUser;
    if (user == null) return;
    await supabase.from('users').update(data).eq('id', user.id);
  }

  // ─── IMAGE UPLOAD ─────────────────────────────────────────────

  // StudentMarketPlace-এর uploadImage থেকে adapted
  // পরিবর্তন: 'post-images' bucket → 'agri-images' bucket, folder parameter রাখা হয়েছে
  Future<String?> uploadImage(File file, String folder) async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}';
      final path = '${user.id}/$folder/$fileName';

      await supabase.storage.from('agri-images').upload(path, file);

      return supabase.storage.from('agri-images').getPublicUrl(path);
    } catch (e) {
      rethrow;
    }
  }

  // ─── PRODUCTS (adapted from posts) ───────────────────────────

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final data = await supabase
        .from('products')
        .select(
      '*, farmer:users!products_farmer_id_fkey(full_name, profile_image_url, address)',
    )
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getProductsByZone(int zone) async {
    final data = await supabase
        .from('products')
        .select(
      '*, farmer:users!products_farmer_id_fkey(full_name, profile_image_url, address)',
    )
        .eq('zone', zone)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

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
    final user = currentUser;
    if (user == null) return;

    await ensureUserProfileExists(user);

    await supabase.from('products').insert({
      'farmer_id': user.id,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'zone': zone,
      'quantity': quantity,
      'unit': unit,
      'image_url': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'is_available': true,
    });
  }

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
    await supabase.from('products').update({
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'zone': zone,
      'quantity': quantity,
      'unit': unit,
      'image_url': imageUrl,
    }).eq('id', productId);
  }

  Future<void> deleteProduct(String productId) async {
    await supabase.from('products').delete().eq('id', productId);
  }

  Future<List<Map<String, dynamic>>> getMyProducts() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    final data = await supabase
        .from('products')
        .select('*')
        .eq('farmer_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  // ─── ORDERS ───────────────────────────────────────────────────

  Future<void> createOrder({
    required String productId,
    required String farmerId,
    required double quantity,
    required double totalPrice,
    String? deliveryAddress,
    String? notes,
  }) async {
    final user = currentUser;
    if (user == null) return;

    await supabase.from('orders').insert({
      'buyer_id': user.id,
      'product_id': productId,
      'farmer_id': farmerId,
      'quantity': quantity,
      'total_price': totalPrice,
      'delivery_address': deliveryAddress,
      'notes': notes,
      'status': 'pending',
    });
  }

  Future<List<Map<String, dynamic>>> getMyOrdersAsBuyer() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    final data = await supabase
        .from('orders')
        .select(
      '*, product:products(*), farmer:users!orders_farmer_id_fkey(full_name)',
    )
        .eq('buyer_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getIncomingOrdersAsFarmer() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    final data = await supabase
        .from('orders')
        .select(
      '*, product:products(*), buyer:users!orders_buyer_id_fkey(full_name, phone)',
    )
        .eq('farmer_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await supabase
        .from('orders')
        .update({'status': status}).eq('id', orderId);
  }

  // ─── CHAT (adapted from MyChatApp) ────────────────────────────

  // MyChatApp-এর room logic থেকে adapted
  Future<String> createOrGetChatRoom(String otherUserId) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    // আগে existing room খোঁজো
    final existing = await supabase
        .from('chat_rooms')
        .select('id')
        .or('and(user1_id.eq.$userId,user2_id.eq.$otherUserId),and(user1_id.eq.$otherUserId,user2_id.eq.$userId)')
        .maybeSingle();

    if (existing != null) return existing['id'];

    // নতুন room তৈরি করো
    final newRoom = await supabase.from('chat_rooms').insert({
      'user1_id': userId,
      'user2_id': otherUserId,
    }).select().single();

    return newRoom['id'];
  }

  // MyChatApp-এর message.dart toMap() থেকে adapted
  Future<void> sendMessage({
    required String roomId,
    required String content,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await supabase.from('messages').insert({
      'room_id': roomId,
      'sender_id': userId,
      'content': content,
    });
  }

  Stream<List<Map<String, dynamic>>> listenToMessages(String roomId) {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: true)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  Future<List<Map<String, dynamic>>> getChatRooms() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    final data = await supabase
        .from('chat_rooms')
        .select('*, user1:users!chat_rooms_user1_id_fkey(full_name, profile_image_url), user2:users!chat_rooms_user2_id_fkey(full_name, profile_image_url)')
        .or('user1_id.eq.$userId,user2_id.eq.$userId')
        .order('updated_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  // ─── REVIEWS ──────────────────────────────────────────────────

  Future<void> submitReview({
    required String farmerId,
    required String orderId,
    required int rating,
    String? comment,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await supabase.from('reviews').insert({
      'buyer_id': userId,
      'farmer_id': farmerId,
      'order_id': orderId,
      'rating': rating,
      'comment': comment,
    });
  }

  Future<List<Map<String, dynamic>>> getFarmerReviews(String farmerId) async {
    final data = await supabase
        .from('reviews')
        .select('*, buyer:users!reviews_buyer_id_fkey(full_name)')
        .eq('farmer_id', farmerId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  // ─── WATCHLIST (adapted from favorites) ───────────────────────

  // StudentMarketPlace-এর toggleFavorite থেকে adapted
  Future<void> toggleWatchlist(String productId, bool isWatchlisted) async {
    final user = currentUser;
    if (user == null) return;

    if (isWatchlisted) {
      await supabase.from('watchlist').insert({
        'user_id': user.id,
        'product_id': productId,
      });
    } else {
      await supabase
          .from('watchlist')
          .delete()
          .eq('user_id', user.id)
          .eq('product_id', productId);
    }
  }

  Future<bool> isWatchlisted(String productId) async {
    final userId = currentUser?.id;
    if (userId == null) return false;

    final data = await supabase
        .from('watchlist')
        .select()
        .eq('user_id', userId)
        .eq('product_id', productId)
        .maybeSingle();
    return data != null;
  }
}
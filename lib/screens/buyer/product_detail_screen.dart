import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_constants.dart';
import '../common/chat_screen.dart';
import 'farmer_profile_view_screen.dart';
import 'place_order_screen.dart';
import '../../services/supabase_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  const ProductDetailScreen({super.key, required this.product});
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _supabase = Supabase.instance.client;
  bool _isWatchlisted = false;
  List<Map<String, dynamic>> _reviews = [];
  double _qty = 1;

  @override
  void initState() {
    super.initState();
    _checkWatchlist();
    _loadReviews();
  }

  Future<void> _checkWatchlist() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    final data = await _supabase.from('watchlist').select().eq('user_id', userId).eq('product_id', widget.product['id']).maybeSingle();
    setState(() => _isWatchlisted = data != null);
  }

  Future<void> _loadReviews() async {
    final data = await _supabase
        .from('reviews')
        .select('*, buyer:users!reviews_buyer_id_fkey(full_name)')
        .eq('farmer_id', widget.product['farmer_id'])
        .order('created_at', ascending: false)
        .limit(5);
    setState(() => _reviews = List<Map<String, dynamic>>.from(data));
  }

  Future<void> _toggleWatchlist() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    if (_isWatchlisted) {
      await _supabase.from('watchlist').delete().eq('user_id', userId).eq('product_id', widget.product['id']);
    } else {
      await _supabase.from('watchlist').insert({'user_id': userId, 'product_id': widget.product['id']});
    }
    setState(() => _isWatchlisted = !_isWatchlisted);
  }

  double get _totalPrice => _qty * (widget.product['price'] as num).toDouble();

  double get _avgRating {
    if (_reviews.isEmpty) return 0;
    return _reviews.fold(0, (s, r) => s + ((r['rating'] ?? 0) as int)) / _reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final zone = product['zone'] ?? 1;
    final zoneConfig = zoneConfigs.firstWhere((z) => z.zone == zone, orElse: () => zoneConfigs.first);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [

          // ── Image App Bar ──
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            actions: [
              IconButton(
                icon: Icon(_isWatchlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: _isWatchlisted ? Colors.red : Colors.white),
                onPressed: _toggleWatchlist,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: product['image_url'] != null
                  ? CachedNetworkImage(imageUrl: product['image_url'], fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppColors.background),
                  errorWidget: (_, __, ___) => Container(color: AppColors.background, child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 48)))
                  : Container(
                color: AppColors.background,
                child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 64),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: pagePadding,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── Title & Price ──
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Text(product['title'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                  Text('৳${product['price']}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ]),
                Text('প্রতি ${product['unit'] ?? 'কেজি'}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),

                const SizedBox(height: 8),

                // ── Zone & Rating ──
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: zoneConfig.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(zoneConfig.nameBn, style: TextStyle(fontSize: 12, color: zoneConfig.color, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(zoneConfig.deliveryTimeBn, style: const TextStyle(fontSize: 12, color: AppColors.accent)),
                  ),
                  const Spacer(),
                  if (_reviews.isNotEmpty) ...[
                    const Icon(Icons.star_rounded, color: AppColors.accent, size: 16),
                    Text(_avgRating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(' (${_reviews.length})', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ]),

                const SizedBox(height: 16),

                // ── Farmer Info ──
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FarmerProfileViewScreen(farmerId: product['farmer_id']))),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                        child: Text((product['farmer']?['full_name'] ?? 'ক')[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(product['farmer']?['full_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(product['farmer']?['address'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ])),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                    ]),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Description ──
                if (product['description'] != null && product['description'].toString().isNotEmpty) ...[
                  const Text('বিবরণ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(product['description'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
                  const SizedBox(height: 12),
                ],

                // ── Quantity Selector ──
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('পরিমাণ নির্বাচন করুন', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('সর্বোচ্চ: ${product['quantity']} ${product['unit']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ]),
                    const SizedBox(height: 10),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _QtyButton(icon: Icons.remove_rounded, onTap: () { if (_qty > 1) setState(() => _qty--); }),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text('$_qty ${product['unit'] ?? 'কেজি'}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      _QtyButton(icon: Icons.add_rounded, onTap: () {
                        if (_qty < (product['quantity'] as num).toDouble()) setState(() => _qty++);
                      }, filled: true),
                    ]),
                  ]),
                ),

                const SizedBox(height: 12),

                // ── Reviews ──
                if (_reviews.isNotEmpty) ...[
                  const Text('রিভিউ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  ..._reviews.take(3).map((r) => _ReviewTile(review: r)),
                ],

                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),

      // ── Bottom Bar ──
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(left: 16, right: 16, top: 10, bottom: MediaQuery.of(context).padding.bottom + 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: Row(children: [
          // Chat button
          GestureDetector(
            onTap: () async {
              final service = SupabaseService();
              final roomId = await service.createOrGetChatRoom(product['farmer_id']);
              if (context.mounted) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                  roomId: roomId,
                  otherUserName: product['farmer']?['full_name'] ?? 'কৃষক',
                )));
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          // Order button
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => PlaceOrderScreen(product: product, quantity: _qty, totalPrice: _totalPrice),
              )),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(vertical: 14)),
              child: Text('অর্ডার করুন - ৳${_totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  const _QtyButton({required this.icon, required this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary),
        ),
        child: Icon(icon, color: filled ? Colors.white : AppColors.primary, size: 18),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Map<String, dynamic> review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final rating = review['rating'] ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(review['buyer']?['full_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const Spacer(),
          Row(children: List.generate(5, (i) => Icon(Icons.star_rounded, size: 13, color: i < rating ? AppColors.accent : Colors.grey.shade300))),
        ]),
        if (review['comment'] != null && review['comment'].toString().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(review['comment'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ]),
    );
  }
}
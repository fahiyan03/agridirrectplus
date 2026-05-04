import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_constants.dart';

class FarmerPublicProfileScreen extends StatefulWidget {
  final String farmerId;
  const FarmerPublicProfileScreen({super.key, required this.farmerId});

  @override
  State<FarmerPublicProfileScreen> createState() => _FarmerPublicProfileScreenState();
}

class _FarmerPublicProfileScreenState extends State<FarmerPublicProfileScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _farmer;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Future.wait এর বদলে আলাদাভাবে load করা হচ্ছে - type error ঠিক করা হয়েছে
  Future<void> _loadData() async {
    try {
      final farmer = await _supabase
          .from('users')
          .select('*')
          .eq('id', widget.farmerId)
          .single();

      final products = await _supabase
          .from('products')
          .select('*')
          .eq('farmer_id', widget.farmerId)
          .eq('is_available', true);

      final reviews = await _supabase
          .from('reviews')
          .select('*, buyer:users!reviews_buyer_id_fkey(full_name)')
          .eq('farmer_id', widget.farmerId)
          .order('created_at', ascending: false);

      setState(() {
        _farmer = farmer;
        _products = List<Map<String, dynamic>>.from(products);
        _reviews = List<Map<String, dynamic>>.from(reviews);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  double get _avgRating {
    if (_reviews.isEmpty) return 0;
    final total = _reviews.fold(0, (sum, r) => sum + ((r['rating'] ?? 0) as int));
    return total / _reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    if (_farmer == null) {
      return const Scaffold(body: Center(child: Text('কৃষকের তথ্য পাওয়া যায়নি')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const SizedBox(height: 40),
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    backgroundImage: _farmer!['profile_image_url'] != null
                        ? CachedNetworkImageProvider(_farmer!['profile_image_url'])
                        : null,
                    child: _farmer!['profile_image_url'] == null
                        ? Text(
                      (_farmer!['full_name'] ?? 'ক')[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    )
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(_farmer!['full_name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('কৃষক', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                ]),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: pagePadding,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                const SizedBox(height: 16),

                // Stats
                Row(children: [
                  _StatBox(value: '${_products.length}', label: 'পণ্য'),
                  const SizedBox(width: 10),
                  _StatBox(value: '${_reviews.length}', label: 'রিভিউ'),
                  const SizedBox(width: 10),
                  _StatBox(value: _avgRating.toStringAsFixed(1), label: 'রেটিং', isRating: true),
                ]),

                const SizedBox(height: 16),

                // Contact Info
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    if (_farmer!['phone'] != null)
                      _ContactRow(icon: Icons.phone_rounded, text: _farmer!['phone']),
                    if (_farmer!['address'] != null)
                      _ContactRow(icon: Icons.location_on_rounded, text: _farmer!['address']),
                  ]),
                ),

                const SizedBox(height: 16),

                // Products
                const Text('সক্রিয় পণ্য', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 10),
                if (_products.isEmpty)
                  const Text('কোনো পণ্য নেই', style: TextStyle(color: AppColors.textSecondary))
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _products.length,
                    itemBuilder: (_, i) => _ProductMiniCard(product: _products[i]),
                  ),

                const SizedBox(height: 16),

                // Reviews
                const Text('ক্রেতাদের মতামত', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 10),
                if (_reviews.isEmpty)
                  const Text('এখনো কোনো রিভিউ নেই', style: TextStyle(color: AppColors.textSecondary))
                else
                  ..._reviews.take(5).map((r) => _ReviewCard(review: r)),

                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value, label;
  final bool isRating;
  const _StatBox({required this.value, required this.label, this.isRating = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (isRating) const Icon(Icons.star_rounded, color: AppColors.accent, size: 16),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ]),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ]),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ContactRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 13)),
      ]),
    );
  }
}

class _ProductMiniCard extends StatelessWidget {
  final Map<String, dynamic> product;
  const _ProductMiniCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: product['image_url'] != null
              ? CachedNetworkImage(
            imageUrl: product['image_url'],
            height: 90,
            width: double.infinity,
            fit: BoxFit.cover,
          )
              : Container(
            height: 90,
            color: AppColors.background,
            child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 32),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('৳${product['price']}/${product['unit']}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
          ]),
        ),
      ]),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final rating = review['rating'] ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(review['buyer']?['full_name'] ?? 'ক্রেতা', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const Spacer(),
          Row(children: List.generate(5, (i) => Icon(Icons.star_rounded, size: 14, color: i < rating ? AppColors.accent : Colors.grey.shade300))),
        ]),
        if (review['comment'] != null && review['comment'].toString().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(review['comment'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ]),
    );
  }
}
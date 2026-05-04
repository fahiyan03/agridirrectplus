import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_constants.dart';

class ListingModerationScreen extends StatefulWidget {
  const ListingModerationScreen({super.key});
  @override
  State<ListingModerationScreen> createState() => _ListingModerationScreenState();
}

class _ListingModerationScreenState extends State<ListingModerationScreen> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  bool _showAvailable = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() => _showAvailable = _tabController.index == 0);
      _loadProducts();
    });
    _loadProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from('products')
          .select('*, farmer:users!products_farmer_id_fkey(full_name, email)')
          .eq('is_available', _showAvailable)
          .order('created_at', ascending: false);
      setState(() { _products = List<Map<String, dynamic>>.from(data); _isLoading = false; });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAvailability(String productId, bool current) async {
    try {
      await _supabase.from('products').update({'is_available': !current}).eq('id', productId);
      await _loadProducts();
      if (mounted) context.showSuccessSnackBar(message: current ? 'পণ্য বন্ধ করা হয়েছে' : 'পণ্য সক্রিয় করা হয়েছে');
    } catch (e) {
      if (mounted) context.showErrorSnackBar(message: e.toString());
    }
  }

  Future<void> _deleteProduct(String productId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('পণ্য মুছবেন?'),
        content: const Text('এই পণ্যটি স্থায়ীভাবে মুছে যাবে।'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('বাতিল')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('মুছুন', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _supabase.from('products').delete().eq('id', productId);
      await _loadProducts();
      if (mounted) context.showSuccessSnackBar(message: 'পণ্য মুছে ফেলা হয়েছে');
    } catch (e) {
      if (mounted) context.showErrorSnackBar(message: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: const Text('লিস্টিং মডারেশন'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.accent,
          tabs: const [Tab(text: 'সক্রিয় লিস্টিং'), Tab(text: 'বন্ধ লিস্টিং')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(2, (_) => _isLoading
            ? preloader
            : _products.isEmpty
            ? const Center(child: Text('কোনো লিস্টিং নেই', style: TextStyle(color: AppColors.textSecondary)))
            : RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadProducts,
          child: ListView.builder(
            padding: pagePadding,
            itemCount: _products.length,
            itemBuilder: (_, i) => _ProductModerationCard(
              product: _products[i],
              onToggle: () => _toggleAvailability(_products[i]['id'], _products[i]['is_available'] ?? true),
              onDelete: () => _deleteProduct(_products[i]['id']),
            ),
          ),
        )),
      ),
    );
  }
}

class _ProductModerationCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onToggle, onDelete;
  const _ProductModerationCard({required this.product, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isAvailable = product['is_available'] ?? true;
    final zone = product['zone'] ?? 1;
    final zoneColor = zoneConfigs.firstWhere((z) => z.zone == zone, orElse: () => zoneConfigs.first).color;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        ClipRRect(
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
          child: product['image_url'] != null
              ? CachedNetworkImage(imageUrl: product['image_url'], width: 80, height: 90, fit: BoxFit.cover)
              : Container(width: 80, height: 90, color: AppColors.background, child: const Icon(Icons.eco_rounded, color: AppColors.primary)),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text('কৃষক: ${product['farmer']?['full_name'] ?? ''}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Text('৳${product['price']}/${product['unit']}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 5),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: zoneColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text('জোন $zone', style: TextStyle(fontSize: 10, color: zoneColor, fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (isAvailable ? AppColors.error : AppColors.success).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(isAvailable ? 'বন্ধ করুন' : 'চালু করুন',
                        style: TextStyle(fontSize: 10, color: isAvailable ? AppColors.error : AppColors.success, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(onTap: onDelete, child: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error)),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }
}
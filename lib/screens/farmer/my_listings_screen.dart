import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/product_provider.dart';
import 'add_listing_screen.dart';
import 'edit_listing_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});
  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadMyProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('আমার লিস্টিং'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddListingScreen())),
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) return preloader;

          if (provider.myProducts.isEmpty) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.primary.withOpacity(0.3)),
                const SizedBox(height: 16),
                const Text('এখনো কোনো লিস্টিং নেই', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddListingScreen())),
                  icon: const Icon(Icons.add),
                  label: const Text('প্রথম লিস্টিং যোগ করুন'),
                ),
              ]),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => provider.loadMyProducts(),
            child: ListView.builder(
              padding: pagePadding,
              itemCount: provider.myProducts.length,
              itemBuilder: (context, index) {
                final product = provider.myProducts[index];
                return _ListingCard(product: product, onDelete: () async {
                  final confirm = await _showDeleteDialog(context);
                  if (confirm == true) {
                    await provider.deleteProduct(product['id']);
                    if (context.mounted) context.showSuccessSnackBar(message: 'লিস্টিং মুছে ফেলা হয়েছে');
                  }
                });
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddListingScreen())),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<bool?> _showDeleteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('লিস্টিং মুছবেন?'),
        content: const Text('এই লিস্টিংটি স্থায়ীভাবে মুছে যাবে।'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('বাতিল')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('মুছুন', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onDelete;
  const _ListingCard({required this.product, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isAvailable = product['is_available'] ?? true;
    final zone = product['zone'] ?? 1;
    final zoneColor = zoneConfigs.firstWhere((z) => z.zone == zone, orElse: () => zoneConfigs.first).color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.primary.withOpacity(0.1))),
      child: Row(children: [
        // Image
        ClipRRect(
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
          child: product['image_url'] != null
              ? CachedNetworkImage(imageUrl: product['image_url'], width: 90, height: 90, fit: BoxFit.cover,
              placeholder: (_, __) => Container(width: 90, height: 90, color: AppColors.background),
              errorWidget: (_, __, ___) => _PlaceholderImage())
              : _PlaceholderImage(),
        ),

        // Info
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(product['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: (isAvailable ? AppColors.success : AppColors.error).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(isAvailable ? 'সক্রিয়' : 'অনুপলব্ধ', style: TextStyle(fontSize: 10, color: isAvailable ? AppColors.success : AppColors.error, fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 4),
              Text('৳${product['price']}/${product['unit'] ?? 'কেজি'}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
              Text('${product['quantity']} ${product['unit'] ?? 'কেজি'} বাকি', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: zoneColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text('জোন $zone', style: TextStyle(fontSize: 10, color: zoneColor, fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditListingScreen(product: product))),
                  child: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                GestureDetector(onTap: onDelete, child: const Icon(Icons.delete_outline, size: 18, color: AppColors.error)),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90, height: 90,
      color: AppColors.background,
      child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 32),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_constants.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;
  final bool showFarmerName;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.showFarmerName = true,
  });

  @override
  Widget build(BuildContext context) {
    final zone      = product['zone'] ?? 1;
    final zoneColor = zoneConfigs.firstWhere((z) => z.zone == zone, orElse: () => zoneConfigs.first).color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: product['image_url'] != null
                ? CachedNetworkImage(
              imageUrl:    product['image_url'],
              height:      110,
              width:       double.infinity,
              fit:         BoxFit.cover,
              placeholder: (_, __) => _placeholder(),
              errorWidget: (_, __, ___) => _placeholder(),
            )
                : _placeholder(),
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product['title'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              if (showFarmerName) ...[
                const SizedBox(height: 2),
                Text(product['farmer']?['full_name'] ?? '',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('৳${product['price']}/${product['unit'] ?? 'কেজি'}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: zoneColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text('জোন $zone', style: TextStyle(fontSize: 9, color: zoneColor, fontWeight: FontWeight.w600)),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: 110,
      color: AppColors.background,
      child: const Center(child: Icon(Icons.eco_rounded, color: AppColors.primary, size: 36)),
    );
  }
}
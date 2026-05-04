import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;
  final bool isFarmerView;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.isFarmerView = false,
  });

  @override
  Widget build(BuildContext context) {
    final status = order['status'] ?? 'pending';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
              child: Text(
                order['product']?['title'] ?? 'পণ্য',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: OrderStatus.toColor(status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                OrderStatus.toBangla(status),
                style: TextStyle(fontSize: 11, color: OrderStatus.toColor(status), fontWeight: FontWeight.w600),
              ),
            ),
          ]),

          const SizedBox(height: 5),

          Text(
            isFarmerView
                ? 'ক্রেতা: ${order['buyer']?['full_name'] ?? ''}'
                : 'কৃষক: ${order['farmer']?['full_name'] ?? ''}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          Text(
            '${order['quantity']} ${order['product']?['unit'] ?? 'কেজি'}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),

          const Divider(height: 12),

          Text(
            'মোট: ৳${order['total_price']}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
          ),
        ]),
      ),
    );
  }
}
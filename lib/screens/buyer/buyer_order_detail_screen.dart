import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/order_provider.dart';
import '../common/chat_screen.dart';
import 'rate_review_screen.dart';
import '../../services/supabase_service.dart';

class BuyerOrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order;
  final bool showReview;

  const BuyerOrderDetailScreen({super.key, required this.order, this.showReview = false});

  @override
  Widget build(BuildContext context) {
    final status = order['status'] ?? 'pending';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('অর্ডারের বিবরণ')),
      body: SingleChildScrollView(
        padding: pagePadding,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Status ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: OrderStatus.toColor(status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: OrderStatus.toColor(status).withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              Icon(Icons.circle, color: OrderStatus.toColor(status), size: 12),
              const SizedBox(width: 8),
              Text(OrderStatus.toBangla(status), style: TextStyle(color: OrderStatus.toColor(status), fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
          ),

          const SizedBox(height: 16),

          // ── Product Info ──
          _SectionCard(title: 'পণ্যের তথ্য', children: [
            _InfoRow('পণ্যের নাম', order['product']?['title'] ?? '-'),
            _InfoRow('পরিমাণ', '${order['quantity']} ${order['product']?['unit'] ?? 'কেজি'}'),
            _InfoRow('মোট মূল্য', '৳${order['total_price']}'),
          ]),

          const SizedBox(height: 12),

          // ── Farmer Info ──
          _SectionCard(title: 'কৃষকের তথ্য', children: [
            _InfoRow('নাম', order['farmer']?['full_name'] ?? '-'),
            _InfoRow('ফোন', order['farmer']?['phone'] ?? '-'),
          ]),

          const SizedBox(height: 12),

          // ── Delivery Info ──
          _SectionCard(title: 'ডেলিভারির তথ্য', children: [
            _InfoRow('ঠিকানা', order['delivery_address'] ?? '-'),
            if (order['notes'] != null && order['notes'].toString().isNotEmpty)
              _InfoRow('নোট', order['notes']),
          ]),

          const SizedBox(height: 16),

          // ── Chat Button ──
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final service = SupabaseService();
                final roomId = await service.createOrGetChatRoom(order['farmer_id']);
                if (context.mounted) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                    roomId: roomId,
                    otherUserName: order['farmer']?['full_name'] ?? 'কৃষক',
                  )));
                }
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('কৃষকের সাথে কথা বলুন'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary)),
            ),
          ),

          const SizedBox(height: 12),

          // ── Cancel Button ──
          if (status == 'pending')
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await context.read<OrderProvider>().updateStatus(order['id'], OrderStatus.cancelled);
                  if (context.mounted) {
                    context.showSnackBar(message: 'অর্ডার বাতিল করা হয়েছে');
                    Navigator.pop(context);
                  }
                },
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                child: const Text('অর্ডার বাতিল করুন'),
              ),
            ),

          // ── Review Button ──
          if (status == 'delivered' || showReview)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RateReviewScreen(order: order))),
                icon: const Icon(Icons.star_rounded),
                label: const Text('রিভিউ দিন', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              ),
            ),

          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
        const Divider(height: 12),
        ...children,
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 90, child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
        const Text(': '),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/order_provider.dart';
import '../common/chat_screen.dart';
import '../../services/supabase_service.dart';

// FIX: StatelessWidget → StatefulWidget — mounted properly কাজ করবে
class FarmerOrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const FarmerOrderDetailScreen({super.key, required this.order});

  @override
  State<FarmerOrderDetailScreen> createState() =>
      _FarmerOrderDetailScreenState();
}

class _FarmerOrderDetailScreenState extends State<FarmerOrderDetailScreen> {
  bool _chatLoading = false;

  Future<void> _openChat() async {
    setState(() => _chatLoading = true);
    try {
      final roomId = await SupabaseService()
          .createOrGetChatRoom(widget.order['buyer_id']);
      // FIX: StatefulWidget এ mounted properly কাজ করে
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            roomId: roomId,
            otherUserName:
            widget.order['buyer']?['full_name'] ?? 'ক্রেতা',
          ),
        ),
      );
    } catch (e) {
      if (mounted) context.showErrorSnackBar(message: e.toString());
    } finally {
      if (mounted) setState(() => _chatLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.order['status']?.toString() ?? 'pending';
    final provider = context.read<OrderProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('অর্ডারের বিবরণ')),
      body: SingleChildScrollView(
        padding: pagePadding,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Status Banner ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // FIX: withOpacity → withValues
              color: OrderStatus.toColor(status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: OrderStatus.toColor(status).withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              Icon(Icons.circle, color: OrderStatus.toColor(status), size: 12),
              const SizedBox(width: 8),
              Text(
                OrderStatus.toBangla(status),
                style: TextStyle(
                    color: OrderStatus.toColor(status),
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ]),
          ),

          const SizedBox(height: 16),

          // ── Product Info ──
          _SectionCard(title: 'পণ্যের তথ্য', children: [
            _InfoRow('পণ্যের নাম',
                widget.order['product']?['title']?.toString() ?? '-'),
            _InfoRow('পরিমাণ',
                '${widget.order['quantity']} ${widget.order['product']?['unit']?.toString() ?? 'কেজি'}'),
            _InfoRow('একক মূল্য',
                '৳${widget.order['product']?['price']?.toString() ?? '-'}'),
            _InfoRow('মোট মূল্য',
                '৳${widget.order['total_price']?.toString() ?? '-'}'),
          ]),

          const SizedBox(height: 12),

          // ── Buyer Info ──
          _SectionCard(title: 'ক্রেতার তথ্য', children: [
            _InfoRow('নাম',
                widget.order['buyer']?['full_name']?.toString() ?? '-'),
            _InfoRow(
                'ফোন', widget.order['buyer']?['phone']?.toString() ?? '-'),
            _InfoRow('ঠিকানা',
                widget.order['delivery_address']?.toString() ?? '-'),
            if (widget.order['notes'] != null &&
                widget.order['notes'].toString().isNotEmpty)
              _InfoRow('নোট', widget.order['notes'].toString()),
          ]),

          const SizedBox(height: 12),

          // ── Chat Button ──
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _chatLoading ? null : _openChat,
              icon: _chatLoading
                  ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary))
                  : const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('ক্রেতার সাথে কথা বলুন'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary)),
            ),
          ),

          const SizedBox(height: 16),

          // ── Action Buttons ──

          // Pending: গ্রহণ বা বাতিল
          if (status == 'pending') ...[
            Row(children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await provider.updateStatus(
                        widget.order['id'], OrderStatus.accepted,
                        isFarmer: true);
                    if (mounted) {
                      context.showSuccessSnackBar(
                          message: 'অর্ডার গৃহীত হয়েছে');
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('অর্ডার গ্রহণ করুন'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await provider.updateStatus(
                        widget.order['id'], OrderStatus.rejected,
                        isFarmer: true);
                    if (mounted) {
                      context.showErrorSnackBar(
                          message: 'অর্ডার বাতিল করা হয়েছে');
                      Navigator.pop(context);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error)),
                  child: const Text('বাতিল করুন'),
                ),
              ),
            ]),
          ],

          // FIX: accepted → ready (আগে সরাসরি delivered এ যেত)
          if (status == 'accepted') ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  await provider.updateStatus(
                      widget.order['id'], 'ready',
                      isFarmer: true);
                  if (mounted) {
                    context.showSuccessSnackBar(
                        message: 'অর্ডার প্রস্তুত!');
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent),
                child: const Text('প্রস্তুত হয়েছে',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],

          // FIX: ready → delivered (নতুন step)
          if (status == 'ready') ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  await provider.updateStatus(
                      widget.order['id'], OrderStatus.delivered,
                      isFarmer: true);
                  if (mounted) {
                    context.showSuccessSnackBar(
                        message: 'ডেলিভারি সম্পন্ন!');
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success),
                child: const Text('ডেলিভারি সম্পন্ন করুন',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],

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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // FIX: withOpacity → withValues
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.primary)),
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
        SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13))),
        const Text(': ',
            style: TextStyle(color: AppColors.textSecondary)),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
    );
  }
}

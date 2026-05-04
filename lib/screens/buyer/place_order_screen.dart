import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/order_provider.dart';

class PlaceOrderScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final double quantity;
  final double totalPrice;

  const PlaceOrderScreen({
    super.key,
    required this.product,
    required this.quantity,
    required this.totalPrice,
  });

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (_addressCtrl.text.trim().isEmpty) {
      context.showErrorSnackBar(message: 'ডেলিভারি ঠিকানা দিন');
      return;
    }

    setState(() => _isLoading = true);

    final success = await context.read<OrderProvider>().placeOrder(
      productId: widget.product['id'],
      farmerId: widget.product['farmer_id'],
      quantity: widget.quantity,
      totalPrice: widget.totalPrice,
      deliveryAddress: _addressCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      _showSuccessDialog();
    } else {
      context.showErrorSnackBar(message: 'অর্ডার দিতে সমস্যা হয়েছে');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 48),
          ),
          const SizedBox(height: 16),
          const Text('অর্ডার সফল!',
              style:
              TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text(
              'কৃষক আপনার অর্ডার গ্রহণ করলে জানানো হবে।',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary)),
        ]),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // FIX: pushAndRemoveUntil route stack ভাঙত
                // এখন শুধু dialog বন্ধ করো + PlaceOrderScreen বন্ধ করো
                // BuyerDashboard এর "আমার অর্ডার" tab handle করবে
                Navigator.pop(context); // dialog বন্ধ
                Navigator.pop(context); // PlaceOrderScreen বন্ধ
              },
              child: const Text('ঠিক আছে'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('অর্ডার নিশ্চিত করুন')),
      body: SingleChildScrollView(
        padding: pagePadding,
        child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Order Summary ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12)),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('অর্ডারের সারসংক্ষেপ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.primary)),
                  const Divider(height: 16),
                  _SummaryRow('পণ্য', product['title']?.toString() ?? ''),
                  _SummaryRow('কৃষক',
                      product['farmer']?['full_name']?.toString() ?? ''),
                  _SummaryRow('পরিমাণ',
                      '${widget.quantity} ${product['unit']?.toString() ?? 'কেজি'}'),
                  _SummaryRow(
                      'একক মূল্য', '৳${product['price']?.toString() ?? ''}'),
                  const Divider(height: 12),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('মোট মূল্য',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(
                            '৳${widget.totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppColors.primary)),
                      ]),
                ]),
          ),

          const SizedBox(height: 16),

          // ── Zone Delivery Info ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              // FIX: withOpacity → withValues
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.local_shipping_rounded,
                  color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ডেলিভারি সময়: ${zoneConfigs.firstWhere((z) => z.zone == (product['zone'] ?? 1), orElse: () => zoneConfigs.first).deliveryTimeBn}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 16),

          // ── Delivery Address ──
          const Text('ডেলিভারি ঠিকানা *',
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _addressCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText:
              'পূর্ণ ঠিকানা লিখুন - বাড়ি নম্বর, রাস্তা, এলাকা...',
            ),
          ),

          const SizedBox(height: 12),

          // ── Notes ──
          const Text('বিশেষ নির্দেশনা (ঐচ্ছিক)',
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
                hintText: 'কৃষককে যা জানাতে চান...'),
          ),

          const SizedBox(height: 24),

          // ── Place Order Button ──
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                  'অর্ডার দিন - ৳${widget.totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ),

          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ]),
    );
  }
}
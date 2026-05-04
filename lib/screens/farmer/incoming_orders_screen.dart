import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/order_provider.dart';
import 'farmer_order_detail_screen.dart';

class IncomingOrdersScreen extends StatefulWidget {
  const IncomingOrdersScreen({super.key});
  @override
  State<IncomingOrdersScreen> createState() => _IncomingOrdersScreenState();
}

class _IncomingOrdersScreenState extends State<IncomingOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadIncomingOrdersAsFarmer();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('আসা অর্ডার'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.accent,
          labelStyle:
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'অপেক্ষমাণ'),
            Tab(text: 'গৃহীত'),
            Tab(text: 'ডেলিভারি'),
            Tab(text: 'সব'),
          ],
        ),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) return preloader;

          final all = provider.incomingOrders;
          final pending =
          all.where((o) => o['status'] == 'pending').toList();
          final accepted =
          all.where((o) => o['status'] == 'accepted').toList();
          final delivered =
          all.where((o) => o['status'] == 'delivered').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _OrderList(
                  orders: pending,
                  onRefresh: () =>
                      provider.loadIncomingOrdersAsFarmer()),
              _OrderList(
                  orders: accepted,
                  onRefresh: () =>
                      provider.loadIncomingOrdersAsFarmer()),
              _OrderList(
                  orders: delivered,
                  onRefresh: () =>
                      provider.loadIncomingOrdersAsFarmer()),
              _OrderList(
                  orders: all,
                  onRefresh: () =>
                      provider.loadIncomingOrdersAsFarmer()),
            ],
          );
        },
      ),
    );
  }
}

// ─── Order List ───────────────────────────────────────────────

class _OrderList extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final VoidCallback onRefresh;
  const _OrderList({required this.orders, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(
          child: Text('কোনো অর্ডার নেই',
              style: TextStyle(color: AppColors.textSecondary)));
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: pagePadding,
        itemCount: orders.length,
        itemBuilder: (_, i) => _OrderCard(order: orders[i]),
      ),
    );
  }
}

// ─── Order Card ───────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    // FIX: Consumer দিয়ে fresh data নাও — action button press এর পর stale data দেখাবে না
    return Consumer<OrderProvider>(
      builder: (ctx, provider, _) {
        final fresh = provider.incomingOrders.firstWhere(
              (o) => o['id'] == order['id'],
          orElse: () => order,
        );

        final status = fresh['status']?.toString() ?? 'pending';
        final buyerName =
            fresh['buyer']?['full_name']?.toString() ?? 'ক্রেতা';
        final initial =
        buyerName.isNotEmpty ? buyerName[0].toUpperCase() : 'ক';

        return GestureDetector(
          onTap: () => Navigator.push(
              ctx,
              MaterialPageRoute(
                  builder: (_) =>
                      FarmerOrderDetailScreen(order: fresh))),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              // FIX: withOpacity → withValues
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.1)),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Header ──
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          CircleAvatar(
                            radius: 16,
                            // FIX: withOpacity → withValues
                            backgroundColor:
                            AppColors.primaryLight.withValues(alpha: 0.2),
                            child: Text(initial,
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ),
                          const SizedBox(width: 8),
                          Text(buyerName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                        ]),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            // FIX: withOpacity → withValues
                            color: OrderStatus.toColor(status)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(OrderStatus.toBangla(status),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: OrderStatus.toColor(status),
                                  fontWeight: FontWeight.w600)),
                        ),
                      ]),

                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  Text(
                      '${fresh['product']?['title']?.toString() ?? 'পণ্য'} - ${fresh['quantity']} ${fresh['product']?['unit']?.toString() ?? 'কেজি'}',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('মোট: ৳${fresh['total_price']}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontSize: 14)),
                        if (fresh['delivery_address'] != null)
                          Flexible(
                              child: Text(
                                  fresh['delivery_address'].toString(),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)),
                      ]),

                  // ── Pending Actions ──
                  if (status == 'pending') ...[
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await provider.updateStatus(
                                fresh['id'], OrderStatus.accepted,
                                isFarmer: true);
                            if (ctx.mounted) {
                              ctx.showSuccessSnackBar(
                                  message: 'অর্ডার গৃহীত হয়েছে');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8)),
                          child: const Text('গ্রহণ করুন',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await provider.updateStatus(
                                fresh['id'], OrderStatus.rejected,
                                isFarmer: true);
                            if (ctx.mounted) {
                              ctx.showErrorSnackBar(
                                  message: 'অর্ডার বাতিল করা হয়েছে');
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side:
                            const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(
                                vertical: 8),
                          ),
                          child: const Text('বাতিল করুন',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ),
                    ]),
                  ],

                  // ── Accepted → Ready ──
                  if (status == 'accepted') ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await provider.updateStatus(
                              fresh['id'], 'ready',
                              isFarmer: true);
                          if (ctx.mounted) {
                            ctx.showSuccessSnackBar(
                                message: 'অর্ডার প্রস্তুত!');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            padding:
                            const EdgeInsets.symmetric(vertical: 8)),
                        child: const Text('প্রস্তুত হয়েছে',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],

                  // ── Ready → Delivered ──
                  if (status == 'ready') ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await provider.updateStatus(
                              fresh['id'], OrderStatus.delivered,
                              isFarmer: true);
                          if (ctx.mounted) {
                            ctx.showSuccessSnackBar(
                                message: 'ডেলিভারি সম্পন্ন হয়েছে!');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding:
                            const EdgeInsets.symmetric(vertical: 8)),
                        child: const Text('ডেলিভারি সম্পন্ন',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ]),
          ),
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/order_provider.dart';
import 'buyer_order_detail_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});
  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadMyOrdersAsBuyer();
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
        title: const Text('আমার অর্ডার'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.accent,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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

          final all = provider.myOrders;
          final pending = all.where((o) => o['status'] == 'pending').toList();
          final accepted = all.where((o) => o['status'] == 'accepted').toList();
          final delivered = all.where((o) => o['status'] == 'delivered').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _OrderList(orders: pending, onRefresh: () => provider.loadMyOrdersAsBuyer()),
              _OrderList(orders: accepted, onRefresh: () => provider.loadMyOrdersAsBuyer()),
              _OrderList(orders: delivered, onRefresh: () => provider.loadMyOrdersAsBuyer()),
              _OrderList(orders: all, onRefresh: () => provider.loadMyOrdersAsBuyer()),
            ],
          );
        },
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final VoidCallback onRefresh;
  const _OrderList({required this.orders, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.shopping_bag_outlined, size: 56, color: AppColors.textHint),
        SizedBox(height: 12),
        Text('কোনো অর্ডার নেই', style: TextStyle(color: AppColors.textSecondary)),
      ]));
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

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final status = order['status'] ?? 'pending';

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BuyerOrderDetailScreen(order: order))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
              decoration: BoxDecoration(color: OrderStatus.toColor(status).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(OrderStatus.toBangla(status), style: TextStyle(fontSize: 11, color: OrderStatus.toColor(status), fontWeight: FontWeight.w600)),
            ),
          ]),

          const SizedBox(height: 6),

          Text('কৃষক: ${order['farmer']?['full_name'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text('${order['quantity']} ${order['product']?['unit'] ?? 'কেজি'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),

          const Divider(height: 12),

          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('মোট: ৳${order['total_price']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
            if (status == 'delivered')
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BuyerOrderDetailScreen(order: order, showReview: true))),
                child: const Text('রিভিউ দিন', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            if (status == 'pending')
              GestureDetector(
                onTap: () async {
                  await context.read<OrderProvider>().updateStatus(order['id'], OrderStatus.cancelled);
                  if (context.mounted) context.showSnackBar(message: 'অর্ডার বাতিল করা হয়েছে');
                },
                child: const Text('বাতিল করুন', style: TextStyle(color: AppColors.error, fontSize: 12)),
              ),
          ]),
        ]),
      ),
    );
  }
}
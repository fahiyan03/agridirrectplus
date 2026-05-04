import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import 'user_management_screen.dart';
import 'listing_moderation_screen.dart';
import 'category_management_screen.dart';
import 'broadcast_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _supabase = Supabase.instance.client;

  int _farmerCount = 0;
  int _buyerCount = 0;
  int _productCount = 0;
  int _orderCount = 0;
  int _pendingCount = 0;
  List<Map<String, dynamic>> _recentOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      // আলাদা আলাদা count query - FetchOptions ছাড়া
      final farmers = await _supabase
          .from('users')
          .select('id')
          .eq('role', 'farmer');

      final buyers = await _supabase
          .from('users')
          .select('id')
          .eq('role', 'buyer');

      final products = await _supabase
          .from('products')
          .select('id')
          .eq('is_available', true);

      final orders = await _supabase
          .from('orders')
          .select('id');

      final pending = await _supabase
          .from('orders')
          .select('id')
          .eq('status', 'pending');

      final recentOrders = await _supabase
          .from('orders')
          .select('*, product:products(title), buyer:users!orders_buyer_id_fkey(full_name)')
          .order('created_at', ascending: false)
          .limit(5);

      setState(() {
        _farmerCount  = (farmers as List).length;
        _buyerCount   = (buyers as List).length;
        _productCount = (products as List).length;
        _orderCount   = (orders as List).length;
        _pendingCount = (pending as List).length;
        _recentOrders = List<Map<String, dynamic>>.from(recentOrders);
        _isLoading    = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: const Text('অ্যাডমিন প্যানেল'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? preloader
          : RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Stats Grid ──
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.6,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _StatCard(label: 'মোট কৃষক',       value: '$_farmerCount',  icon: Icons.agriculture_rounded,      color: AppColors.primary),
                  _StatCard(label: 'মোট ক্রেতা',      value: '$_buyerCount',   icon: Icons.people_rounded,           color: AppColors.info),
                  _StatCard(label: 'সক্রিয় পণ্য',    value: '$_productCount', icon: Icons.inventory_2_rounded,      color: AppColors.accent),
                  _StatCard(label: 'অপেক্ষমাণ অর্ডার', value: '$_pendingCount', icon: Icons.pending_actions_rounded,  color: AppColors.error),
                ],
              ),

              const SizedBox(height: 16),

              // ── Pie Chart ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ব্যবহারকারী বিভাজন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 160,
                      child: Row(children: [
                        Expanded(
                          child: PieChart(
                            PieChartData(
                              sections: [
                                PieChartSectionData(
                                  value: _farmerCount > 0 ? _farmerCount.toDouble() : 1,
                                  color: AppColors.primary,
                                  title: 'কৃষক',
                                  radius: 55,
                                  titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                PieChartSectionData(
                                  value: _buyerCount > 0 ? _buyerCount.toDouble() : 1,
                                  color: AppColors.info,
                                  title: 'ক্রেতা',
                                  radius: 55,
                                  titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                              sectionsSpace: 2,
                              centerSpaceRadius: 30,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _LegendItem(color: AppColors.primary, label: 'কৃষক',      value: '$_farmerCount'),
                            const SizedBox(height: 8),
                            _LegendItem(color: AppColors.info,    label: 'ক্রেতা',     value: '$_buyerCount'),
                            const SizedBox(height: 8),
                            _LegendItem(color: AppColors.accent,  label: 'পণ্য',       value: '$_productCount'),
                            const SizedBox(height: 8),
                            _LegendItem(color: AppColors.error,   label: 'অপেক্ষমাণ', value: '$_pendingCount'),
                          ],
                        ),
                      ]),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Quick Actions ──
              const Text('ম্যানেজমেন্ট', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _ActionCard(
                    icon: Icons.manage_accounts_rounded,
                    label: 'ইউজার ম্যানেজমেন্ট',
                    color: AppColors.primary,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementScreen())),
                  ),
                  _ActionCard(
                    icon: Icons.fact_check_rounded,
                    label: 'লিস্টিং মডারেশন',
                    color: AppColors.accent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ListingModerationScreen())),
                  ),
                  _ActionCard(
                    icon: Icons.category_rounded,
                    label: 'ক্যাটাগরি ম্যানেজমেন্ট',
                    color: AppColors.info,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryManagementScreen())),
                  ),
                  _ActionCard(
                    icon: Icons.campaign_rounded,
                    label: 'ব্রডকাস্ট নোটিফিকেশন',
                    color: const Color(0xFF7B1FA2),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BroadcastScreen())),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Recent Orders ──
              const Text('সাম্প্রতিক অর্ডার', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              if (_recentOrders.isEmpty)
                const Text('কোনো অর্ডার নেই', style: TextStyle(color: AppColors.textSecondary))
              else
                ..._recentOrders.map((o) => _RecentOrderTile(order: o)),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Widgets ─────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ])),
      ]),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 2)),
        ]),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label, value;
  const _LegendItem({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text('$label: $value', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
    ]);
  }
}

class _RecentOrderTile extends StatelessWidget {
  final Map<String, dynamic> order;
  const _RecentOrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final status = order['status'] ?? 'pending';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(order['product']?['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(order['buyer']?['full_name'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('৳${order['total_price']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: OrderStatus.toColor(status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              OrderStatus.toBangla(status),
              style: TextStyle(fontSize: 10, color: OrderStatus.toColor(status), fontWeight: FontWeight.w600),
            ),
          ),
        ]),
      ]),
    );
  }
}
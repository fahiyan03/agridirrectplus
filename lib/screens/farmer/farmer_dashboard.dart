import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/weather_service.dart';
import '../common/chat_list_screen.dart';
import '../common/notification_screen.dart';
import '../common/profile_screen.dart';
import 'add_listing_screen.dart';
import 'my_listings_screen.dart';
import 'incoming_orders_screen.dart';
import 'crop_doctor_upload_screen.dart';
import 'weather_detail_screen.dart';

class FarmerDashboard extends StatefulWidget {
  const FarmerDashboard({super.key});

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard> {
  int _currentIndex = 0;
  Map<String, dynamic>? _weather;
  bool _weatherLoading = true;

  // FIX: Debounce — বারবার refresh এ duplicate API call বন্ধ
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    if (_isRefreshing) return;
    if (mounted) setState(() => _isRefreshing = true);

    if (!mounted) return;
    await Future.wait([
      context.read<OrderProvider>().loadIncomingOrdersAsFarmer(),
      context.read<ProductProvider>().loadMyProducts(),
    ]);

    try {
      final weather = await WeatherService().getCurrentWeather();
      if (mounted) {
        setState(() {
          _weather = weather;
          _weatherLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _weatherLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeTab(weather: _weather, weatherLoading: _weatherLoading, onRefresh: _loadData),
      const MyListingsScreen(),
      const IncomingOrdersScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'হোম'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_rounded), label: 'লিস্টিং'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_rounded), label: 'অর্ডার'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'প্রোফাইল'),
        ],
      ),
    );
  }
}

// ─── Home Tab ────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  final Map<String, dynamic>? weather;
  final bool weatherLoading;
  final VoidCallback onRefresh;

  const _HomeTab({
    required this.weather,
    required this.weatherLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    // FIX: context.select — শুধু দরকারি field watch, unnecessary rebuild বন্ধ
    final name = context.select<AuthProvider, String>(
          (auth) => auth.profile?['full_name'] ?? 'কৃষক',
    );
    final orders = context.select<OrderProvider, List<Map<String, dynamic>>>(
          (p) => p.incomingOrders,
    );
    final productCount = context.select<ProductProvider, int>(
          (p) => p.myProducts.length,
    );

    final pendingOrders = orders.where((o) => o['status'] == 'pending').length;

    // FIX: type-safe totalSales — price String হলেও crash নেই
    final totalSales = orders
        .where((o) => o['status'] == 'delivered')
        .fold(0.0, (sum, o) {
      final price = o['total_price'];
      final double value = (price is num)
          ? price.toDouble()
          : double.tryParse(price?.toString() ?? '') ?? 0.0;
      return sum + value;
    });

    // FIX: toList() — Iterable → List, Column children এ safe
    final recentOrders = orders.take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('স্বাগতম, $name',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const Text('কৃষক ড্যাশবোর্ড',
                style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ChatListScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => onRefresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Stats ──
              Row(children: [
                _StatCard(
                  label: 'মোট বিক্রি',
                  value: '৳${totalSales.toStringAsFixed(0)}',
                  color: AppColors.primary,
                  icon: Icons.monetization_on_rounded,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  label: 'লিস্টিং',
                  value: '$productCount',
                  color: AppColors.accent,
                  icon: Icons.inventory_2_rounded,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  label: 'নতুন অর্ডার',
                  value: '$pendingOrders',
                  color: AppColors.info,
                  icon: Icons.shopping_bag_rounded,
                ),
              ]),

              const SizedBox(height: 16),

              // ── Quick Actions ──
              const Text('দ্রুত অ্যাকশন',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              Row(children: [
                _QuickAction(
                  icon: Icons.add_circle_rounded,
                  label: 'নতুন লিস্টিং',
                  color: AppColors.primary,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AddListingScreen())),
                ),
                const SizedBox(width: 10),
                _QuickAction(
                  icon: Icons.biotech_rounded,
                  label: 'Crop Doctor',
                  color: AppColors.accent,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CropDoctorUploadScreen())),
                ),
                const SizedBox(width: 10),
                _QuickAction(
                  icon: Icons.wb_sunny_rounded,
                  label: 'আবহাওয়া',
                  color: const Color(0xFF1565C0),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const WeatherDetailScreen())),
                ),
              ]),

              const SizedBox(height: 16),

              // ── Weather ──
              _WeatherCard(weather: weather, isLoading: weatherLoading),

              const SizedBox(height: 16),

              // ── Recent Orders ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('সাম্প্রতিক অর্ডার',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  TextButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const IncomingOrdersScreen())),
                    child: const Text('সব দেখুন',
                        style: TextStyle(color: AppColors.primary, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              if (recentOrders.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: const Center(
                    child: Text('এখনো কোনো অর্ডার নেই',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                )
              else
                ...recentOrders.map((o) => _RecentOrderTile(order: o)),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stat Card ───────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _StatCard(
      {required this.label,
        required this.value,
        required this.color,
        required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          // FIX: withOpacity → withValues
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary)),
        ]),
      ),
    );
  }
}

// ─── Quick Action ─────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon,
        required this.label,
        required this.color,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            // FIX: withOpacity → withValues
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: color, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}

// ─── Weather Card ─────────────────────────────────────────────

class _WeatherCard extends StatelessWidget {
  final Map<String, dynamic>? weather;
  final bool isLoading;
  const _WeatherCard({required this.weather, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: isLoading
          ? const SizedBox(
        height: 40,
        child: Center(
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2)),
      )
          : Row(children: [
        const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('আজকের আবহাওয়া',
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
                // FIX: null-safe weather keys
                Text(
                  weather != null
                      ? "${weather?['temp']?.toString() ?? '--'}°C - ${weather?['description']?.toString() ?? ''}"
                      : 'তথ্য পাওয়া যায়নি',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
                if (weather != null)
                  Text(
                    "আর্দ্রতা: ${weather?['humidity']?.toString() ?? '--'}% | বায়ু: ${weather?['wind_speed']?.toString() ?? '--'} m/s",
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 10),
                  ),
              ]),
        ),
        TextButton(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) => const WeatherDetailScreen())),
          child: const Text('বিস্তারিত',
              style: TextStyle(color: Colors.white, fontSize: 11)),
        ),
      ]),
    );
  }
}

// ─── Recent Order Tile ────────────────────────────────────────

class _RecentOrderTile extends StatelessWidget {
  final Map<String, dynamic> order;
  const _RecentOrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final status = order['status']?.toString() ?? 'pending';
    // FIX: null-safe buyer name ও initial
    final buyerName =
        order['buyer']?['full_name']?.toString() ?? 'ক্রেতা';
    final initial = buyerName.isNotEmpty ? buyerName[0].toUpperCase() : 'ক';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // FIX: withOpacity → withValues
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 18,
          // FIX: withOpacity → withValues
          backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
          child: Text(initial,
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(buyerName,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
            Text(
              "${order['product']?['title']?.toString() ?? ''} - ${order['quantity']} ${order['product']?['unit']?.toString() ?? 'কেজি'}",
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            // FIX: withOpacity → withValues
            color: OrderStatus.toColor(status).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            OrderStatus.toBangla(status),
            style: TextStyle(
                fontSize: 10,
                color: OrderStatus.toColor(status),
                fontWeight: FontWeight.w600),
          ),
        ),
      ]),
    );
  }
}
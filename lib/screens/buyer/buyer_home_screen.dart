/*
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class BuyerHomeScreen extends StatelessWidget {
  const BuyerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.profile?['full_name'] ?? 'ক্রেতা';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AgriDirect+'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_basket,
                  size: 64, color: AppColors.accent),
            ),
            const SizedBox(height: 20),
            Text(
              'স্বাগতম, $name!',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'ক্রেতার হোম স্ক্রিন তৈরি হচ্ছে...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}*/

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../common/chat_list_screen.dart';
import '../common/notification_screen.dart';
import '../common/profile_screen.dart';
import 'map_view_screen.dart';
import 'product_detail_screen.dart';
import 'search_filter_screen.dart';
import 'my_orders_screen.dart';

class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({super.key});
  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadAllProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _HomeTab(),
      const MapViewScreen(),
      const MyOrdersScreen(),
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
          BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'ম্যাপ'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_rounded), label: 'অর্ডার'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'প্রোফাইল'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();
  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  int _selectedZone = 0;

  final List<Map<String, dynamic>> _zones = [
    {'label': 'সব', 'zone': 0},
    {'label': 'জোন ১', 'zone': 1},
    {'label': 'জোন ২', 'zone': 2},
    {'label': 'জোন ৩', 'zone': 3},
    {'label': 'জোন ৪', 'zone': 4},
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<ProductProvider>();
    final name = auth.profile?['full_name'] ?? 'ক্রেতা';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [

        // ── Header ──
        Container(
          color: AppColors.primary,
          child: SafeArea(
            bottom: false,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('স্বাগতম, $name', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Row(children: [
                        const Icon(Icons.location_on_rounded, color: Colors.white70, size: 13),
                        const SizedBox(width: 3),
                        const Text('আপনার এলাকা', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ]),
                    ]),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen())),
                  ),
                ]),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchFilterScreen())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(children: [
                      Icon(Icons.search_rounded, color: Colors.white70, size: 18),
                      SizedBox(width: 8),
                      Text('পণ্য খুঁজুন...', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ]),
                  ),
                ),
              ),

              // Zone tabs
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  itemCount: _zones.length,
                  itemBuilder: (_, i) {
                    final isSelected = _selectedZone == _zones[i]['zone'];
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedZone = _zones[i]['zone']);
                        context.read<ProductProvider>().loadAllProducts(zone: _zones[i]['zone'] == 0 ? null : _zones[i]['zone']);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _zones[i]['label'],
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? AppColors.primary : Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ]),
          ),
        ),

        // ── Product Grid ──
        Expanded(
          child: provider.isLoading
              ? preloader
              : provider.products.isEmpty
              ? const Center(child: Text('কোনো পণ্য পাওয়া যায়নি', style: TextStyle(color: AppColors.textSecondary)))
              : RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => provider.loadAllProducts(zone: _selectedZone == 0 ? null : _selectedZone),
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.78,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: provider.products.length,
              itemBuilder: (_, i) => _ProductCard(product: provider.products[i]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final zone = product['zone'] ?? 1;
    final zoneColor = zoneConfigs.firstWhere((z) => z.zone == zone, orElse: () => zoneConfigs.first).color;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: product['image_url'] != null
                ? CachedNetworkImage(imageUrl: product['image_url'], height: 110, width: double.infinity, fit: BoxFit.cover,
                placeholder: (_, __) => Container(height: 110, color: AppColors.background),
                errorWidget: (_, __, ___) => _PlaceholderImg())
                : _PlaceholderImg(),
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(product['farmer']?['full_name'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('৳${product['price']}/${product['unit'] ?? 'কেজি'}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
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
}

class _PlaceholderImg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      color: AppColors.background,
      child: const Center(child: Icon(Icons.eco_rounded, color: AppColors.primary, size: 36)),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_constants.dart';
import 'product_detail_screen.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});
  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  final _mapController = MapController();
  final _supabase = Supabase.instance.client;

  LatLng _center = const LatLng(23.8103, 90.4125); // Dhaka default
  List<Map<String, dynamic>> _products = [];
  Map<String, dynamic>? _selectedProduct;
  bool _isLoading = true;
  int _selectedZone = 1;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _getLocation();
    await _loadProducts();
  }

  Future<void> _getLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() => _center = LatLng(pos.latitude, pos.longitude));
    } catch (_) {
      // Dhaka default ব্যবহার করবে
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from('products')
          .select('*, farmer:users!products_farmer_id_fkey(full_name, address)')
          .eq('is_available', true)
          .eq('zone', _selectedZone)
          .not('latitude', 'is', null)
          .not('longitude', 'is', null);

      setState(() { _products = List<Map<String, dynamic>>.from(data); _isLoading = false; });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('কৃষকদের ম্যাপ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            onPressed: () {
              _mapController.move(_center, 13);
              setState(() => _selectedProduct = null);
            },
          ),
        ],
      ),
      body: Stack(children: [

        // ── Map ──
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: 13,
            onTap: (_, __) => setState(() => _selectedProduct = null),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.agridirectplus.agridirectplus',
            ),

            // User location marker
            MarkerLayer(markers: [
              Marker(
                point: _center,
                width: 30,
                height: 30,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.info,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 16),
                ),
              ),
            ]),

            // Product markers
            MarkerLayer(
              markers: _products.map((p) {
                final lat = p['latitude'] as double?;
                final lon = p['longitude'] as double?;
                if (lat == null || lon == null) return null;

                return Marker(
                  point: LatLng(lat, lon),
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedProduct = p),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
                      ),
                      child: const Icon(Icons.eco_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                );
              }).whereType<Marker>().toList(),
            ),
          ],
        ),

        // ── Zone selector ──
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)]),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              ...List.generate(4, (i) {
                final zone = i + 1;
                final isSelected = _selectedZone == zone;
                final color = zoneConfigs[i].color;
                return GestureDetector(
                  onTap: () { setState(() => _selectedZone = zone); _loadProducts(); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? color : color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('জোন $zone', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : color)),
                  ),
                );
              }),
            ]),
          ),
        ),

        // ── Loading ──
        if (_isLoading)
          const Center(child: CircularProgressIndicator(color: AppColors.primary)),

        // ── Selected Product Card ──
        if (_selectedProduct != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _ProductBottomCard(
              product: _selectedProduct!,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: _selectedProduct!))),
              onClose: () => setState(() => _selectedProduct = null),
            ),
          ),

        // ── No products message ──
        if (!_isLoading && _products.isEmpty && _selectedProduct == null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: const Text('এই জোনে কোনো কৃষক পাওয়া যায়নি', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
            ),
          ),
      ]),
    );
  }
}

class _ProductBottomCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap, onClose;
  const _ProductBottomCard({required this.product, required this.onTap, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10)],
      ),
      child: Row(children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.eco_rounded, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(product['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(product['farmer']?['full_name'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text('৳${product['price']}/${product['unit']}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        ])),
        Column(children: [
          GestureDetector(onTap: onClose, child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textHint)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
              child: const Text('দেখুন', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ]),
    );
  }
}
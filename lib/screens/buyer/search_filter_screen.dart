import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_constants.dart';
import 'product_detail_screen.dart';

class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key});
  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  final _searchCtrl = TextEditingController();
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  int? _selectedZone;
  String? _selectedCategory;
  double _maxPrice = 1000;
  bool _filtersVisible = false;

  final List<String> _categories = ['সবজি', 'ফল', 'মাছ', 'দুধ', 'ডিম', 'চাল', 'আলু', 'পেঁয়াজ', 'মশলা', 'মুরগি'];

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    setState(() => _isLoading = true);
    try {
      var q = _supabase
          .from('products')
          .select('*, farmer:users!products_farmer_id_fkey(full_name, address)')
          .eq('is_available', true);

      if (query.isNotEmpty) q = q.ilike('title', '%$query%');
      if (_selectedZone != null) q = q.eq('zone', _selectedZone!);
      if (_selectedCategory != null) q = q.eq('category', _selectedCategory!);
      if (_maxPrice < 1000) q = q.lte('price', _maxPrice);

      final data = await q.order('created_at', ascending: false);
      setState(() { _results = List<Map<String, dynamic>>.from(data); _isLoading = false; });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _clearFilters() {
    setState(() { _selectedZone = null; _selectedCategory = null; _maxPrice = 1000; });
    _search(_searchCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('পণ্য খুঁজুন'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _selectedZone != null || _selectedCategory != null,
              child: const Icon(Icons.tune_rounded),
            ),
            onPressed: () => setState(() => _filtersVisible = !_filtersVisible),
          ),
        ],
      ),
      body: Column(children: [

        // Search bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchCtrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'পণ্যের নাম লিখুন...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () { _searchCtrl.clear(); _search(''); })
                  : null,
            ),
            onChanged: (v) => _search(v),
          ),
        ),

        // Filters
        if (_filtersVisible)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('ফিল্টার', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                TextButton(onPressed: _clearFilters, child: const Text('সব মুছুন', style: TextStyle(color: AppColors.error, fontSize: 12))),
              ]),

              // Zone filter
              const Text('জোন', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Wrap(spacing: 8, children: [
                ...List.generate(4, (i) {
                  final zone = i + 1;
                  final isSelected = _selectedZone == zone;
                  return GestureDetector(
                    onTap: () { setState(() => _selectedZone = isSelected ? null : zone); _search(_searchCtrl.text); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text('জোন $zone', style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    ),
                  );
                }),
              ]),

              const SizedBox(height: 10),

              // Category filter
              const Text('ক্যাটাগরি', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              SizedBox(
                height: 34,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (_, i) {
                    final isSelected = _selectedCategory == _categories[i];
                    return GestureDetector(
                      onTap: () { setState(() => _selectedCategory = isSelected ? null : _categories[i]); _search(_searchCtrl.text); },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accent : AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(_categories[i], style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppColors.textPrimary)),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Price filter
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('সর্বোচ্চ মূল্য', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text('৳${_maxPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              ]),
              Slider(
                value: _maxPrice,
                min: 10,
                max: 1000,
                divisions: 99,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _maxPrice = v),
                onChangeEnd: (_) => _search(_searchCtrl.text),
              ),
            ]),
          ),

        // Results
        Expanded(
          child: _isLoading
              ? preloader
              : _results.isEmpty
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.search_off_rounded, size: 48, color: AppColors.textHint),
            SizedBox(height: 12),
            Text('কোনো পণ্য পাওয়া যায়নি', style: TextStyle(color: AppColors.textSecondary)),
          ]))
              : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _results.length,
            itemBuilder: (_, i) => _SearchResultTile(product: _results[i]),
          ),
        ),
      ]),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final Map<String, dynamic> product;
  const _SearchResultTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final zone = product['zone'] ?? 1;
    final zoneColor = zoneConfigs.firstWhere((z) => z.zone == zone, orElse: () => zoneConfigs.first).color;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
            child: product['image_url'] != null
                ? CachedNetworkImage(imageUrl: product['image_url'], width: 80, height: 80, fit: BoxFit.cover)
                : Container(width: 80, height: 80, color: AppColors.background, child: const Icon(Icons.eco_rounded, color: AppColors.primary)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(product['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(product['farmer']?['full_name'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 5),
                Row(children: [
                  Text('৳${product['price']}/${product['unit']}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: zoneColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text('জোন $zone', style: TextStyle(fontSize: 10, color: zoneColor, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
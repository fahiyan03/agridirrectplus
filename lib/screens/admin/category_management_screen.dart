import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_constants.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});
  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase.from('categories').select('*').order('zone').order('name');
      setState(() { _categories = List<Map<String, dynamic>>.from(data); _isLoading = false; });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleActive(String id, bool current) async {
    try {
      await _supabase.from('categories').update({'is_active': !current}).eq('id', id);
      await _loadCategories();
    } catch (e) {
      if (mounted) context.showErrorSnackBar(message: e.toString());
    }
  }

  Future<void> _deleteCategory(String id) async {
    try {
      await _supabase.from('categories').delete().eq('id', id);
      await _loadCategories();
      if (mounted) context.showSuccessSnackBar(message: 'ক্যাটাগরি মুছে ফেলা হয়েছে');
    } catch (e) {
      if (mounted) context.showErrorSnackBar(message: e.toString());
    }
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final nameBnCtrl = TextEditingController();
    int selectedZone = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('নতুন ক্যাটাগরি'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ইংরেজি নাম')),
            const SizedBox(height: 10),
            TextField(controller: nameBnCtrl, decoration: const InputDecoration(labelText: 'বাংলা নাম')),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              value: selectedZone,
              decoration: const InputDecoration(labelText: 'জোন'),
              items: List.generate(4, (i) => DropdownMenuItem(value: i + 1, child: Text('জোন ${i + 1}'))),
              onChanged: (v) => setDialogState(() => selectedZone = v!),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || nameBnCtrl.text.trim().isEmpty) return;
                await _supabase.from('categories').insert({
                  'name': nameCtrl.text.trim(),
                  'name_bn': nameBnCtrl.text.trim(),
                  'zone': selectedZone,
                  'is_active': true,
                });
                await _loadCategories();
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) context.showSuccessSnackBar(message: 'ক্যাটাগরি যোগ হয়েছে');
              },
              child: const Text('যোগ করুন'),
            ),
          ],
        ),
      ),
    ).then((_) { nameCtrl.dispose(); nameBnCtrl.dispose(); });
  }

  @override
  Widget build(BuildContext context) {
    // Zone অনুযায়ী group করো
    final Map<int, List<Map<String, dynamic>>> grouped = {};
    for (final cat in _categories) {
      final zone = cat['zone'] ?? 1;
      grouped.putIfAbsent(zone, () => []).add(cat);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: const Text('ক্যাটাগরি ম্যানেজমেন্ট'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: _isLoading
          ? preloader
          : RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadCategories,
        child: ListView(
          padding: pagePadding,
          children: [
            ...List.generate(4, (i) {
              final zone = i + 1;
              final cats = grouped[zone] ?? [];
              final zoneColor = zoneConfigs[i].color;

              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 8, top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: zoneColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(zoneConfigs[i].nameBn, style: TextStyle(fontWeight: FontWeight.bold, color: zoneColor, fontSize: 13)),
                ),
                if (cats.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(left: 12, bottom: 8),
                    child: Text('কোনো ক্যাটাগরি নেই', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                  )
                else
                  ...cats.map((cat) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(cat['name_bn'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(cat['name'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ])),
                      Switch(
                        value: cat['is_active'] ?? true,
                        onChanged: (_) => _toggleActive(cat['id'], cat['is_active'] ?? true),
                        activeColor: AppColors.primary,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                        onPressed: () => _deleteCategory(cat['id']),
                      ),
                    ]),
                  )),
              ]);
            }),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
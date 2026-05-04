import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_constants.dart';

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});
  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  final _supabase = Supabase.instance.client;
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _target = 'all';
  bool _isSending = false;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final data = await _supabase
          .from('notifications')
          .select('*')
          .eq('type', 'broadcast')
          .order('created_at', ascending: false)
          .limit(10);
      setState(() => _history = List<Map<String, dynamic>>.from(data));
    } catch (_) {}
  }

  Future<void> _sendBroadcast() async {
    if (_titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) {
      context.showErrorSnackBar(message: 'শিরোনাম ও বার্তা দিন');
      return;
    }

    setState(() => _isSending = true);

    try {
      // Target users খুঁজে বের করো
      var q = _supabase.from('users').select('id');
      if (_target != 'all') q = q.eq('role', _target);
      final users = await q;

      // সবার জন্য notification insert করো
      final notifications = (users as List).map((u) => {
        'user_id': u['id'],
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
        'type': 'broadcast',
        'is_read': false,
      }).toList();

      // Batch insert - ৫০ টা করে
      for (var i = 0; i < notifications.length; i += 50) {
        final batch = notifications.sublist(i, i + 50 > notifications.length ? notifications.length : i + 50);
        await _supabase.from('notifications').insert(batch);
      }

      await _loadHistory();

      if (mounted) {
        context.showSuccessSnackBar(message: '${notifications.length} জনকে নোটিফিকেশন পাঠানো হয়েছে!');
        _titleCtrl.clear();
        _bodyCtrl.clear();
        setState(() => _target = 'all');
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar(message: e.toString());
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.primaryDark, title: const Text('ব্রডকাস্ট নোটিফিকেশন')),
      body: SingleChildScrollView(
        padding: pagePadding,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Compose Card ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              const Text('নতুন ব্রডকাস্ট', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
              const SizedBox(height: 14),

              // Target
              const Text('প্রাপক', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Row(children: [
                _TargetChip(label: 'সবাই', value: 'all', selected: _target == 'all', onTap: () => setState(() => _target = 'all')),
                const SizedBox(width: 8),
                _TargetChip(label: 'কৃষক', value: 'farmer', selected: _target == 'farmer', onTap: () => setState(() => _target = 'farmer')),
                const SizedBox(width: 8),
                _TargetChip(label: 'ক্রেতা', value: 'buyer', selected: _target == 'buyer', onTap: () => setState(() => _target = 'buyer')),
              ]),

              const SizedBox(height: 14),

              const Text('শিরোনাম *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(hintText: 'নোটিফিকেশনের শিরোনাম লিখুন'),
              ),

              const SizedBox(height: 12),

              const Text('বার্তা *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: _bodyCtrl,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'বিস্তারিত বার্তা লিখুন...'),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _sendBroadcast,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                  icon: _isSending
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, color: Colors.white),
                  label: Text(_isSending ? 'পাঠানো হচ্ছে...' : 'পাঠান', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          // ── History ──
          const Text('পূর্ববর্তী ব্রডকাস্ট', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),

          if (_history.isEmpty)
            const Text('কোনো ব্রডকাস্ট নেই', style: TextStyle(color: AppColors.textSecondary))
          else
            ..._history.map((n) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(n['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                Text(n['body'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
            )),

          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

class _TargetChip extends StatelessWidget {
  final String label, value;
  final bool selected;
  final VoidCallback onTap;
  const _TargetChip({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : Colors.grey.shade300),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textPrimary)),
      ),
    );
  }
}
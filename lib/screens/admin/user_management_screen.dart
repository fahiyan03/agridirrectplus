import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_constants.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});
  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _searchCtrl = TextEditingController();
  late TabController _tabController;
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _currentRole = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      final roles = ['all', 'farmer', 'buyer'];
      setState(() => _currentRole = roles[_tabController.index]);
      _loadUsers();
    });
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({String query = ''}) async {
    setState(() => _isLoading = true);
    try {
      var q = _supabase.from('users').select('*').neq('role', 'admin');
      if (_currentRole != 'all') q = q.eq('role', _currentRole);
      if (query.isNotEmpty) q = q.ilike('full_name', '%$query%');
      final data = await q.order('created_at', ascending: false);
      setState(() { _users = List<Map<String, dynamic>>.from(data); _isLoading = false; });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBan(String userId, bool isBanned) async {
    try {
      await _supabase.from('users').update({'is_banned': !isBanned}).eq('id', userId);
      await _loadUsers(query: _searchCtrl.text);
      if (mounted) {
        context.showSuccessSnackBar(message: isBanned ? 'ব্যান তুলে নেওয়া হয়েছে' : 'ব্যবহারকারী ব্যান করা হয়েছে');
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar(message: e.toString());
    }
  }

  Future<void> _changeRole(String userId, String newRole) async {
    try {
      await _supabase.from('users').update({'role': newRole}).eq('id', userId);
      await _loadUsers(query: _searchCtrl.text);
      if (mounted) context.showSuccessSnackBar(message: 'Role পরিবর্তন হয়েছে');
    } catch (e) {
      if (mounted) context.showErrorSnackBar(message: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: const Text('ইউজার ম্যানেজমেন্ট'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.accent,
          tabs: const [Tab(text: 'সবাই'), Tab(text: 'কৃষক'), Tab(text: 'ক্রেতা')],
        ),
      ),
      body: Column(children: [

        // Search
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'নাম দিয়ে খুঁজুন...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () { _searchCtrl.clear(); _loadUsers(); })
                  : null,
            ),
            onChanged: (v) => _loadUsers(query: v),
          ),
        ),

        // User count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(children: [
            Text('মোট ${_users.length} জন', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ]),
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: List.generate(3, (_) => _isLoading
                ? preloader
                : _users.isEmpty
                ? const Center(child: Text('কোনো ব্যবহারকারী নেই', style: TextStyle(color: AppColors.textSecondary)))
                : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => _loadUsers(query: _searchCtrl.text),
              child: ListView.builder(
                padding: pagePadding,
                itemCount: _users.length,
                itemBuilder: (_, i) => _UserCard(
                  user: _users[i],
                  onToggleBan: () => _toggleBan(_users[i]['id'], _users[i]['is_banned'] ?? false),
                  onChangeRole: (role) => _changeRole(_users[i]['id'], role),
                ),
              ),
            )),
          ),
        ),
      ]),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onToggleBan;
  final ValueChanged<String> onChangeRole;
  const _UserCard({required this.user, required this.onToggleBan, required this.onChangeRole});

  @override
  Widget build(BuildContext context) {
    final isBanned = user['is_banned'] ?? false;
    final role = user['role'] ?? 'buyer';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isBanned ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isBanned ? AppColors.error.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: role == 'farmer' ? AppColors.primaryLight.withValues(alpha: 0.2) : AppColors.info.withValues(alpha: 0.2),
          child: Text((user['full_name'] ?? 'ব')[0].toUpperCase(),
              style: TextStyle(color: role == 'farmer' ? AppColors.primary : AppColors.info, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(user['full_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            if (isBanned) ...[
              const SizedBox(width: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: const Text('ব্যান্ড', style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.bold))),
            ],
          ]),
          Text(user['email'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          Text(user['phone'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ])),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
          onSelected: (value) {
            if (value == 'ban') {
              onToggleBan();
            } else {
              onChangeRole(value);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'ban', child: Row(children: [
              Icon(isBanned ? Icons.lock_open_rounded : Icons.block_rounded, size: 16, color: isBanned ? AppColors.success : AppColors.error),
              const SizedBox(width: 8),
              Text(isBanned ? 'ব্যান তুলুন' : 'ব্যান করুন'),
            ])),
            if (role == 'buyer')
              const PopupMenuItem(value: 'farmer', child: Row(children: [
                Icon(Icons.agriculture_rounded, size: 16, color: AppColors.primary),
                SizedBox(width: 8),
                Text('কৃষক বানান'),
              ])),
            if (role == 'farmer')
              const PopupMenuItem(value: 'buyer', child: Row(children: [
                Icon(Icons.shopping_bag_rounded, size: 16, color: AppColors.info),
                SizedBox(width: 8),
                Text('ক্রেতা বানান'),
              ])),
          ],
        ),
      ]),
    );
  }
}
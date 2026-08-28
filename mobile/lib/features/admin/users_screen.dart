import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/models.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';

/// Admin users — list of admin users with roles and status (read-only).
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<AdminUser> _items = const [];
  List<Map<String, dynamic>> _raw = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = context.read<ApiClient>();
      final res = await api.get('/api/admin/users');
      final list = res is List ? res : const [];
      _raw = list.cast<Map<String, dynamic>>();
      setState(() {
        _items = _raw.map((e) => AdminUser.fromJson(e)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
          ? const LoadingView(message: 'جارٍ تحميل المستخدمين')
          : _error != null
            ? ErrorView(message: 'تعذّر تحميل المستخدمين', onRetry: _load)
            : _items.isEmpty
              ? const EmptyView(message: 'لا يوجد مستخدمون', icon: Icons.people_outline)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: _items.length,
                  itemBuilder: (context, i) => _UserCard(user: _items[i], raw: _raw[i]),
                ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AdminUser user;
  final Map<String, dynamic> raw;
  const _UserCard({required this.user, required this.raw});

  @override
  Widget build(BuildContext context) {
    final status = raw['status']?.toString() ?? 'active';
    final phone = raw['phone']?.toString();
    final createdAt = raw['createdAt'] as String?;
    final initials = (user.name.isNotEmpty ? user.name : user.email ?? '?').substring(0, 1).toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
            child: Text(initials, style: const TextStyle(color: AppTheme.primary, fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(user.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis)),
              StatusBadge(status: status, small: true),
            ]),
            const SizedBox(height: 4),
            if (user.email != null && user.email!.isNotEmpty)
              Row(children: [
                const Icon(Icons.mail_outline, size: 12, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Expanded(child: Text(user.email!, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            if (phone != null && phone.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.phone_outlined, size: 12, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(phone, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ]),
            ],
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: user.roleNames.map((r) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppTheme.info.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
              child: Text(r, style: const TextStyle(fontSize: 10, color: AppTheme.info, fontWeight: FontWeight.w700)),
            )).toList()),
            if (createdAt != null) ...[
              const SizedBox(height: 6),
              Text('أُنشئ: ${_fmtDate(DateTime.tryParse(createdAt) ?? DateTime.now())}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ])),
        ]),
      ),
    );
  }
}

String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

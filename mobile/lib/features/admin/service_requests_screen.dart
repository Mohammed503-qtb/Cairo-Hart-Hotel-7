import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/models.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';

/// Admin service requests — list with status filter and action buttons.
class AdminServiceRequestsScreen extends StatefulWidget {
  const AdminServiceRequestsScreen({super.key});
  @override
  State<AdminServiceRequestsScreen> createState() => _AdminServiceRequestsScreenState();
}

class _AdminServiceRequestsScreenState extends State<AdminServiceRequestsScreen> {
  List<ServiceRequest> _items = const [];
  bool _loading = true;
  String? _error;
  String _status = '';

  final _statuses = const [
    ('', 'الكل'),
    ('new', 'جديد'),
    ('accepted', 'مقبول'),
    ('assigned', 'مُعيَّن'),
    ('in_progress', 'قيد التنفيذ'),
    ('waiting', 'بانتظار'),
    ('completed', 'مكتمل'),
    ('cancelled', 'ملغى'),
    ('rejected', 'مرفوض'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = context.read<ApiClient>();
      final res = await api.get('/api/admin/service-requests', query: _status.isEmpty ? null : {'status': _status});
      final list = res is List ? res : const [];
      setState(() { _items = list.map((e) => ServiceRequest.fromJson(e as Map<String, dynamic>)).toList(); _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _doAction(ServiceRequest req, String action, {String? label}) async {
    String? assignedToId;
    if (action == 'assign') {
      assignedToId = await _askAssignee();
      if (assignedToId == null) return; // cancelled
    }
    String? reason;
    if (action == 'cancel' || action == 'reject') {
      reason = await _askReason(label ?? action);
      if (reason == null) return; // cancelled
    }
    try {
      final api = context.read<ApiClient>();
      await api.patch('/api/admin/service-requests', body: {
        'id': req.id,
        'action': action,
        'assignedToId': ?assignedToId,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تنفيذ الإجراء'), backgroundColor: AppTheme.success));
      }
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل: ${e.toString()}'), backgroundColor: AppTheme.danger));
    }
  }

  Future<String?> _askAssignee() async {
    // Simple text input for assignee ID — a full user-picker would require GET /api/admin/users
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('تعيين إلى'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'معرّف المستخدم المسؤول', border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(c, ctrl.text.trim()), child: const Text('تعيين')),
        ],
      ),
    );
  }

  Future<String?> _askReason(String title) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'السبب (اختياري)', border: OutlineInputBorder()),
          maxLines: 2,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(c, ctrl.text.trim()), child: const Text('تنفيذ')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _statuses.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final s = _statuses[i];
                    final active = s.$1 == _status;
                    return FilterChip(
                      label: Text(s.$2),
                      selected: active,
                      onSelected: (_) { _status = s.$1; _load(); },
                      selectedColor: s.$1.isEmpty ? AppTheme.primary : statusColor(s.$1),
                      backgroundColor: AppTheme.background,
                      labelStyle: TextStyle(color: active ? Colors.white : AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    );
                  },
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(child: LoadingView(message: 'جارٍ تحميل الطلبات'))
            else if (_error != null)
              SliverFillRemaining(child: ErrorView(message: 'تعذّر تحميل الطلبات', onRetry: _load))
            else if (_items.isEmpty)
              const SliverFillRemaining(child: EmptyView(message: 'لا توجد طلبات خدمات', icon: Icons.build_outlined))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                sliver: SliverList.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, i) => _ServiceRequestCard(item: _items[i], onAction: _doAction),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ServiceRequestCard extends StatelessWidget {
  final ServiceRequest item;
  final void Function(ServiceRequest, String, {String? label}) onAction;
  const _ServiceRequestCard({required this.item, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final guest = item.guest;
    final room = item.room;
    final service = item.service;
    final priorityColor = _priorityColor(item.priority);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: priorityColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.flag, color: priorityColor, size: 14),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(item.reference ?? item.id ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800))),
            StatusBadge(status: item.status, small: true),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 4, children: [
            _chip(Icons.category_outlined, _categoryLabel(item.category)),
            if (guest != null) _chip(Icons.person_outline, '${guest['name']?.toString() ?? ''} - ${guest['phone']?.toString() ?? ''}'),
            if (room != null) _chip(Icons.bed_outlined, 'غرفة ${room['number']?.toString() ?? ''}'),
            if (service != null) _chip(Icons.room_service_outlined, service['nameAr']?.toString() ?? ''),
            if (item.assignedTo != null) _chip(Icons.support_agent, 'المسؤول: ${item.assignedTo}'),
          ]),
          if (item.descriptionAr.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(8)),
              child: Text(item.descriptionAr, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
            ),
          ],
          if (item.createdAt != null) ...[
            const SizedBox(height: 4),
            Text('أُنشئ: ${_fmtDateTime(item.createdAt!)}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
          if (item.completedAt != null) ...[
            const SizedBox(height: 2),
            Text('أُنجز: ${_fmtDateTime(item.completedAt!)}', style: const TextStyle(fontSize: 11, color: AppTheme.success)),
          ],
          const Divider(height: 14),
          _buildActions(),
        ]),
      ),
    );
  }

  Widget _buildActions() {
    final s = item.status;
    final actions = <(String, String, IconData, Color)>[];
    if (s == 'new' || s == 'accepted') {
      actions.add(('assign', 'تعيين', Icons.assignment_ind_outlined, AppTheme.info));
      actions.add(('start', 'بدء', Icons.play_arrow, AppTheme.primary));
    }
    if (s == 'assigned' || s == 'accepted') {
      actions.add(('start', 'بدء', Icons.play_arrow, AppTheme.primary));
    }
    if (s == 'in_progress') {
      actions.add(('wait', 'بانتظار', Icons.pause_circle_outline, AppTheme.warning));
      actions.add(('complete', 'إكمال', Icons.check_circle, AppTheme.success));
    }
    if (s == 'waiting') {
      actions.add(('start', 'استئناف', Icons.play_arrow, AppTheme.primary));
      actions.add(('complete', 'إكمال', Icons.check_circle, AppTheme.success));
    }
    if (s != 'completed' && s != 'cancelled' && s != 'rejected') {
      actions.add(('cancel', 'إلغاء', Icons.cancel_outlined, AppTheme.danger));
      actions.add(('reject', 'رفض', Icons.block, AppTheme.danger));
    }
    if (actions.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 6, runSpacing: 6, children: actions.map((a) {
      return OutlinedButton.icon(
        onPressed: () => onAction(item, a.$1, label: a.$2),
        icon: Icon(a.$3, size: 16, color: a.$4),
        label: Text(a.$2, style: TextStyle(color: a.$4, fontWeight: FontWeight.w600, fontSize: 12)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: a.$4.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: const Size(0, 32),
        ),
      );
    }).toList());
  }

  Widget _chip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(6)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: AppTheme.textSecondary),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
    ]),
  );

  Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'high': case 'urgent': return AppTheme.danger;
      case 'normal': return AppTheme.primary;
      case 'low': return AppTheme.textSecondary;
      default: return AppTheme.textSecondary;
    }
  }
}

String _fmtDateTime(DateTime d) => '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';

String _categoryLabel(String category) {
  const map = <String, String>{
    'cleaning': 'تنظيف', 'food': 'طعام', 'maintenance': 'صيانة',
    'transport': 'نقل', 'laundry': 'مغسلة', 'general': 'عام', 'other': 'أخرى',
  };
  return map[category.toLowerCase()] ?? category;
}

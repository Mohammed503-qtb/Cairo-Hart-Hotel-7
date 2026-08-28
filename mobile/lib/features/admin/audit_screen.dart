import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/models.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';

/// Admin audit log — timeline/list of audit logs with entity filter and load-more.
class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});
  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  List<AuditLog> _items = const [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  String _entity = '';
  int _limit = 50;

  final _entities = const [
    ('', 'الكل'),
    ('reservation', 'حجوزات'),
    ('room', 'غرف'),
    ('payment', 'مدفوعات'),
    ('service_request', 'طلبات خدمات'),
    ('room_type', 'أنواع غرف'),
    ('service', 'خدمات'),
    ('offer', 'عروض'),
    ('content_section', 'محتوى'),
    ('hotel_settings', 'إعدادات'),
    ('feature_flag', 'ميزات'),
    ('contact_request', 'تواصل'),
    ('booking_request', 'طلبات حجز'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; _limit = 50; });
    try {
      final api = context.read<ApiClient>();
      final res = await api.get('/api/admin/audit', query: _entity.isEmpty ? {'limit': '$_limit'} : {'entity': _entity, 'limit': '$_limit'});
      final list = res is List ? res : const [];
      setState(() { _items = list.map((e) => AuditLog.fromJson(e as Map<String, dynamic>)).toList(); _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);
    final next = _limit + 50;
    try {
      final api = context.read<ApiClient>();
      final res = await api.get('/api/admin/audit', query: _entity.isEmpty ? {'limit': '$next'} : {'entity': _entity, 'limit': '$next'});
      final list = res is List ? res : const [];
      setState(() { _items = list.map((e) => AuditLog.fromJson(e as Map<String, dynamic>)).toList(); _limit = next; });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
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
                  itemCount: _entities.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final e = _entities[i];
                    final active = e.$1 == _entity;
                    return FilterChip(
                      label: Text(e.$2),
                      selected: active,
                      onSelected: (_) { _entity = e.$1; _load(); },
                      selectedColor: AppTheme.primary,
                      backgroundColor: AppTheme.background,
                      labelStyle: TextStyle(color: active ? Colors.white : AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    );
                  },
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(child: LoadingView(message: 'جارٍ تحميل السجل'))
            else if (_error != null)
              SliverFillRemaining(child: ErrorView(message: 'تعذّر تحميل السجل', onRetry: _load))
            else if (_items.isEmpty)
              const SliverFillRemaining(child: EmptyView(message: 'لا توجد سجلات', icon: Icons.history))
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                sliver: SliverList.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, i) => _AuditCard(log: _items[i]),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  child: Center(
                    child: _loadingMore
                      ? const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                      : OutlinedButton.icon(onPressed: _loadMore, icon: const Icon(Icons.expand_more), label: const Text('تحميل المزيد')),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AuditCard extends StatelessWidget {
  final AuditLog log;
  const _AuditCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final actionColor = _actionColor(log.action);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 4, height: 64,
            decoration: BoxDecoration(color: actionColor.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(log.actor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800))),
              Text(_fmtDateTime(log.createdAt), style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: actionColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                child: Text(log.action, style: TextStyle(fontSize: 10, color: actionColor, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 6),
              Text(_entityLabel(log.entity), style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              Expanded(child: Text(log.entityId.length > 12 ? '#${log.entityId.substring(0, 12)}...' : '#${log.entityId}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontFamily: 'monospace'), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            if (log.oldValue != null || log.newValue != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(8)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (log.oldValue != null && log.oldValue!.isNotEmpty) ...[
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.remove_circle_outline, size: 12, color: AppTheme.danger),
                      const SizedBox(width: 4),
                      Expanded(child: Text(_truncate(log.oldValue!), style: const TextStyle(fontSize: 11, color: AppTheme.danger, fontFamily: 'monospace'))),
                    ]),
                  ],
                  if (log.oldValue != null && log.oldValue!.isNotEmpty && log.newValue != null && log.newValue!.isNotEmpty)
                    const SizedBox(height: 2),
                  if (log.newValue != null && log.newValue!.isNotEmpty) ...[
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.add_circle_outline, size: 12, color: AppTheme.success),
                      const SizedBox(width: 4),
                      Expanded(child: Text(_truncate(log.newValue!), style: const TextStyle(fontSize: 11, color: AppTheme.success, fontFamily: 'monospace'))),
                    ]),
                  ],
                ]),
              ),
            ],
            if (log.reason != null && log.reason!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('السبب: ${log.reason}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontStyle: FontStyle.italic)),
            ],
          ])),
        ]),
      ),
    );
  }

  String _truncate(String s) {
    if (s.length > 200) return '${s.substring(0, 200)}...';
    return s;
  }

  Color _actionColor(String a) {
    if (a.contains('create')) return AppTheme.success;
    if (a.contains('cancel') || a.contains('reject') || a.contains('delete')) return AppTheme.danger;
    if (a.contains('update') || a.contains('edit') || a.contains('change')) return AppTheme.warning;
    if (a.contains('confirm') || a.contains('complete') || a.contains('convert')) return AppTheme.success;
    return AppTheme.info;
  }
}

String _fmtDateTime(DateTime d) => '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';

String _entityLabel(String e) {
  const map = <String, String>{
    'reservation': 'حجز', 'room': 'غرفة', 'payment': 'دفعة',
    'service_request': 'طلب خدمة', 'room_type': 'نوع غرفة', 'service': 'خدمة',
    'offer': 'عرض', 'content_section': 'قسم محتوى', 'hotel_settings': 'إعدادات',
    'feature_flag': 'ميزة', 'contact_request': 'طلب تواصل', 'booking_request': 'طلب حجز',
    'guest': 'ضيف',
  };
  return map[e] ?? e;
}

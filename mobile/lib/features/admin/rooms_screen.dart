import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/models.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';

/// Admin rooms list — grid of rooms with status filter and status-change dialog.
class AdminRoomsScreen extends StatefulWidget {
  const AdminRoomsScreen({super.key});
  @override
  State<AdminRoomsScreen> createState() => _AdminRoomsScreenState();
}

class _AdminRoomsScreenState extends State<AdminRoomsScreen> {
  List<AdminRoom> _items = const [];
  bool _loading = true;
  String? _error;
  String _status = '';
  final _searchCtrl = TextEditingController();
  String _q = '';

  final _statuses = const [
    ('', 'الكل'),
    ('available', 'متاحة'),
    ('reserved', 'محجوزة'),
    ('occupied', 'مشغولة'),
    ('cleaning', 'تنظيف'),
    ('maintenance', 'صيانة'),
    ('blocked', 'محجوبة'),
    ('out_of_service', 'خارج الخدمة'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = context.read<ApiClient>();
      final query = <String, String>{
        if (_status.isNotEmpty) 'status': _status,
        if (_q.isNotEmpty) 'q': _q,
      };
      final res = await api.get('/api/admin/rooms', query: query);
      final list = res is List ? res : const [];
      setState(() { _items = list.map((e) => AdminRoom.fromJson(e as Map<String, dynamic>)).toList(); _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _changeStatus(AdminRoom room) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (c) => _RoomStatusDialog(room: room),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'ابحث برقم الغرفة',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    suffixIcon: IconButton(icon: const Icon(Icons.send, size: 18), onPressed: () { _q = _searchCtrl.text.trim(); _load(); }),
                  ),
                  onSubmitted: (_) { _q = _searchCtrl.text.trim(); _load(); },
                ),
              ),
            ),
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
                      selectedColor: statusColor(s.$1.isEmpty ? 'all' : s.$1),
                      backgroundColor: AppTheme.background,
                      labelStyle: TextStyle(color: active ? Colors.white : AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    );
                  },
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(child: LoadingView(message: 'جارٍ تحميل الغرف'))
            else if (_error != null)
              SliverFillRemaining(child: ErrorView(message: 'تعذّر تحميل الغرف', onRetry: _load))
            else if (_items.isEmpty)
              const SliverFillRemaining(child: EmptyView(message: 'لا توجد غرف مطابقة', icon: Icons.bed_outlined))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: isWide ? 240 : 180,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: isWide ? 1.4 : 1.0,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    childCount: _items.length,
                    (context, i) => _RoomCard(room: _items[i], onTap: () => _changeStatus(_items[i])),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final AdminRoom room;
  final VoidCallback onTap;
  const _RoomCard({required this.room, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(room.status);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: color, width: 3))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.bed, color: color, size: 18),
              ),
              const Spacer(),
              if (room.hasPendingTask)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: AppTheme.warning, shape: BoxShape.circle),
                  child: const Icon(Icons.cleaning_services, color: Colors.white, size: 12),
                ),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(room.number, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              if (room.floor != null) Text('الطابق ${room.floor}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ]),
            Text(room.roomType['nameAr']?.toString() ?? '-', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
            StatusBadge(status: room.status, small: true),
          ]),
        ),
      ),
    );
  }
}

class _RoomStatusDialog extends StatefulWidget {
  final AdminRoom room;
  const _RoomStatusDialog({required this.room});

  @override
  State<_RoomStatusDialog> createState() => _RoomStatusDialogState();
}

class _RoomStatusDialogState extends State<_RoomStatusDialog> {
  final _reasonCtrl = TextEditingController();
  final _statuses = const [
    ('available', 'متاحة'),
    ('reserved', 'محجوزة'),
    ('occupied', 'مشغولة'),
    ('cleaning', 'تنظيف'),
    ('maintenance', 'صيانة'),
    ('blocked', 'محجوبة'),
    ('out_of_service', 'خارج الخدمة'),
  ];
  late String _selected;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.room.status;
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final api = context.read<ApiClient>();
      await api.patch('/api/admin/rooms', body: {
        'id': widget.room.id,
        'status': _selected,
        if (_reasonCtrl.text.trim().isNotEmpty) 'reason': _reasonCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث حالة الغرفة'), backgroundColor: AppTheme.success));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: ${e.toString()}'), backgroundColor: AppTheme.danger));
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('تغيير حالة الغرفة ${widget.room.number}'),
      content: SizedBox(
        width: 320,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('الحالة الحالية:', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          StatusBadge(status: widget.room.status),
          const SizedBox(height: 12),
          const Text('الحالة الجديدة:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          Wrap(spacing: 6, runSpacing: 6, children: _statuses.map((s) {
            final active = s.$1 == _selected;
            return ChoiceChip(
              label: Text(s.$2),
              selected: active,
              onSelected: (_) => setState(() => _selected = s.$1),
              selectedColor: statusColor(s.$1),
              labelStyle: TextStyle(color: active ? Colors.white : AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
            );
          }).toList()),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonCtrl,
            decoration: const InputDecoration(labelText: 'السبب / ملاحظات', hintText: 'اختياري'),
            maxLines: 2,
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: _loading ? null : () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('حفظ'),
        ),
      ],
    );
  }
}

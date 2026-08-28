import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/config.dart';
import '../../core/models.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';

/// Admin reservations list — search + status filter, with create FAB.
class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});
  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  List<AdminReservation> _items = const [];
  int _total = 0;
  bool _loading = true;
  String? _error;
  String _q = '';
  String _status = '';
  final _searchCtrl = TextEditingController();
  final _statuses = const [
    ('', 'الكل'),
    ('awaiting_confirmation', 'بانتظار التأكيد'),
    ('confirmed', 'مؤكد'),
    ('checked_in', 'مسجّل دخول'),
    ('checked_out', 'مسجّل مغادرة'),
    ('completed', 'مكتمل'),
    ('cancelled', 'ملغى'),
    ('no_show', 'لم يحضر'),
    ('rejected', 'مرفوض'),
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
        if (_q.isNotEmpty) 'q': _q,
        if (_status.isNotEmpty) 'status': _status,
      };
      final res = await api.get('/api/admin/reservations', query: query) as Map<String, dynamic>;
      final list = res['items'] as List? ?? const [];
      setState(() {
        _items = list.map((e) => AdminReservation.fromJson(e as Map<String, dynamic>)).toList();
        _total = (res['total'] as num?)?.toInt() ?? _items.length;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _applySearch() {
    _q = _searchCtrl.text.trim();
    _load();
  }

  void _setStatus(String s) {
    _status = s;
    _load();
  }

  Future<void> _openCreate() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _CreateReservationSheet(),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'ابحث برقم التأكيد أو اسم/هاتف الضيف',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send, size: 18),
                          onPressed: _applySearch,
                        ),
                      ),
                      onSubmitted: (_) => _applySearch(),
                    ),
                  ),
                ]),
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
                      onSelected: (_) => _setStatus(s.$1),
                      selectedColor: AppTheme.primary,
                      backgroundColor: AppTheme.background,
                      labelStyle: TextStyle(color: active ? Colors.white : AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text('الإجمالي: $_total حجز', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(child: LoadingView(message: 'جارٍ تحميل الحجوزات'))
            else if (_error != null)
              SliverFillRemaining(child: ErrorView(message: 'تعذّر تحميل الحجوزات', onRetry: _load))
            else if (_items.isEmpty)
              SliverFillRemaining(child: EmptyView(message: 'لا توجد حجوزات مطابقة', icon: Icons.receipt_long_outlined, actionLabel: 'حجز جديد', onAction: _openCreate))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, i) => _ReservationCard(item: _items[i], onTap: () {
                    Navigator.of(context).pushNamed('/admin/reservation', arguments: _items[i].id);
                  }),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('حجز جديد'),
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final AdminReservation item;
  final VoidCallback onTap;
  const _ReservationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(item.confirmationNo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))),
              StatusBadge(status: item.bookingStatus, small: true),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(child: Text(item.guestName, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Icon(Icons.phone_outlined, size: 12, color: AppTheme.textSecondary),
              const SizedBox(width: 2),
              Text(item.guestPhone, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.bed_outlined, size: 12, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Expanded(child: Text(item.roomType, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (item.roomNumber != null) ...[
                const SizedBox(width: 8),
                Text('غرفة ${item.roomNumber}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text('${_fmtDate(item.checkIn)} → ${_fmtDate(item.checkOut)} · ${item.nights} ليالٍ', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ]),
            const Divider(height: 14),
            Row(children: [
              Expanded(
                child: Wrap(spacing: 6, runSpacing: 4, children: [
                  StatusBadge(status: item.paymentStatus, small: true),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppTheme.info.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.info.withValues(alpha: 0.3))),
                    child: Text(item.source, style: const TextStyle(color: AppTheme.info, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(_fmtMoney(item.total), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text('مدفوع ${_fmtMoney(item.paid)}', style: const TextStyle(fontSize: 11, color: AppTheme.success)),
                if (item.remaining > 0)
                  Text('باقي ${_fmtMoney(item.remaining)}', style: const TextStyle(fontSize: 11, color: AppTheme.danger)),
              ]),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _CreateReservationSheet extends StatefulWidget {
  const _CreateReservationSheet();
  @override
  State<_CreateReservationSheet> createState() => _CreateReservationSheetState();
}

class _CreateReservationSheetState extends State<_CreateReservationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _adultsCtrl = TextEditingController(text: '2');
  final _childrenCtrl = TextEditingController(text: '0');
  final _reasonCtrl = TextEditingController();
  DateTime? _checkIn;
  DateTime? _checkOut;
  List<RoomType> _roomTypes = const [];
  String? _roomTypeId;
  String _source = 'admin';
  bool _loading = false;
  bool _loadingRt = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _checkIn = DateTime(now.year, now.month, now.day + 1);
    _checkOut = DateTime(now.year, now.month, now.day + 3);
    _loadRoomTypes();
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _whatsappCtrl.dispose();
    _adultsCtrl.dispose(); _childrenCtrl.dispose(); _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRoomTypes() async {
    try {
      final api = context.read<ApiClient>();
      final res = await api.get('/api/admin/room-types');
      final list = res is List ? res : const [];
      setState(() {
        _roomTypes = list.map((e) => RoomType.fromJson(e as Map<String, dynamic>)).toList();
        _roomTypeId = _roomTypes.isEmpty ? null : _roomTypes.first.id;
        _loadingRt = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingRt = false);
    }
  }

  Future<void> _pickDate({required bool isCheckIn}) async {
    final now = DateTime.now();
    final initial = isCheckIn ? _checkIn! : _checkOut!;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: isCheckIn ? DateTime(now.year, now.month, now.day) : DateTime(now.year, now.month, now.day + 1),
      lastDate: DateTime(now.year + 2),
      helpText: isCheckIn ? 'تاريخ الوصول' : 'تاريخ المغادرة',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppTheme.primary)), child: child!),
    );
    if (picked == null) return;
    setState(() {
      if (isCheckIn) {
        _checkIn = picked;
        if (_checkOut == null || !_checkOut!.isAfter(picked)) {
          _checkOut = picked.add(const Duration(days: 1));
        }
      } else {
        if (_checkIn != null && (picked.isBefore(_checkIn!) || picked == _checkIn)) {
          _checkOut = _checkIn!.add(const Duration(days: 1));
        } else {
          _checkOut = picked;
        }
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_roomTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر نوع الغرفة')));
      return;
    }
    if (_checkIn == null || _checkOut == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدد تاريخي الوصول والمغادرة')));
      return;
    }
    setState(() => _loading = true);
    try {
      final api = context.read<ApiClient>();
      await api.post('/api/admin/reservations', body: {
        'guestName': _nameCtrl.text.trim(),
        'guestPhone': _phoneCtrl.text.trim(),
        if (_whatsappCtrl.text.trim().isNotEmpty) 'guestWhatsapp': _whatsappCtrl.text.trim(),
        'roomTypeId': _roomTypeId,
        'checkIn': _checkIn!.toIso8601String(),
        'checkOut': _checkOut!.toIso8601String(),
        'adults': int.tryParse(_adultsCtrl.text) ?? 1,
        'children': int.tryParse(_childrenCtrl.text) ?? 0,
        'source': _source,
        if (_reasonCtrl.text.trim().isNotEmpty) 'createdReason': _reasonCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنشاء الحجز'), backgroundColor: AppTheme.success));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: ${e.toString()}'), backgroundColor: AppTheme.danger));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final padBottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: padBottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(children: [
                  const Icon(Icons.add_circle, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text('حجز جديد', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                ]),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'اسم الضيف *', prefixIcon: Icon(Icons.person_outline)),
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(labelText: 'رقم الهاتف *', prefixIcon: Icon(Icons.phone_outlined)),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'الهاتف مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _whatsappCtrl,
                      decoration: const InputDecoration(labelText: 'واتساب (اختياري)', prefixIcon: Icon(Icons.chat_outlined)),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    if (_loadingRt)
                      const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)))
                    else
                      DropdownButtonFormField<String>(
                        value: _roomTypeId,
                        decoration: const InputDecoration(labelText: 'نوع الغرفة *', prefixIcon: Icon(Icons.bed_outlined)),
                        items: _roomTypes.map((rt) => DropdownMenuItem(value: rt.id, child: Text('${rt.nameAr} - ${_fmtMoney(rt.basePrice)}'))).toList(),
                        onChanged: (v) => setState(() => _roomTypeId = v),
                      ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _DateField(label: 'الوصول', value: _checkIn, onTap: () => _pickDate(isCheckIn: true))),
                      const SizedBox(width: 10),
                      Expanded(child: _DateField(label: 'المغادرة', value: _checkOut, onTap: () => _pickDate(isCheckIn: false))),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: TextFormField(
                        controller: _adultsCtrl,
                        decoration: const InputDecoration(labelText: 'بالغين', prefixIcon: Icon(Icons.man_outlined)),
                        keyboardType: TextInputType.number,
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: TextFormField(
                        controller: _childrenCtrl,
                        decoration: const InputDecoration(labelText: 'أطفال', prefixIcon: Icon(Icons.child_care_outlined)),
                        keyboardType: TextInputType.number,
                      )),
                    ]),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _source,
                      decoration: const InputDecoration(labelText: 'مصدر الحجز', prefixIcon: Icon(Icons.source_outlined)),
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('إدارة')),
                        DropdownMenuItem(value: 'phone', child: Text('هاتف')),
                        DropdownMenuItem(value: 'whatsapp', child: Text('واتساب')),
                        DropdownMenuItem(value: 'walk_in', child: Text('حضور مباشر')),
                      ],
                      onChanged: (v) => setState(() => _source = v ?? 'admin'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _reasonCtrl,
                      decoration: const InputDecoration(labelText: 'ملاحظات / سبب الإنشاء (اختياري)', prefixIcon: Icon(Icons.note_outlined)),
                      maxLines: 2,
                    ),
                  ]),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  TextButton(onPressed: _loading ? null : () => Navigator.pop(context), child: const Text('إلغاء')),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('حفظ الحجز'),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  const _DateField({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(value == null ? '-' : _fmtDate(value!), style: const TextStyle(fontSize: 14)),
      ),
    );
  }
}

String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

String _fmtMoney(num amount) {
  final s = amount.toStringAsFixed(amount == amount.truncateToDouble() ? 0 : 2);
  return '$s $kCurrencySymbol';
}

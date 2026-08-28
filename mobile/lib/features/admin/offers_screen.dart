import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/config.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';

/// Admin offers — CRUD list with date pickers, discount types, and room-type multi-select.
class AdminOffersScreen extends StatefulWidget {
  const AdminOffersScreen({super.key});
  @override
  State<AdminOffersScreen> createState() => _AdminOffersScreenState();
}

class _AdminOffersScreenState extends State<AdminOffersScreen> {
  List<Map<String, dynamic>> _items = const [];
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
      final res = await api.get('/api/admin/offers');
      final list = res is List ? res : const [];
      setState(() { _items = list.cast<Map<String, dynamic>>(); _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _openForm([Map<String, dynamic>? existing]) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _OfferForm(existing: existing),
    );
    if (result == true) _load();
  }

  Future<void> _archive(Map<String, dynamic> item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('أرشفة عرض'),
        content: Text('سيتم تغيير حالة "${item['nameAr']}" إلى "مؤرشف". متابعة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('أرشفة')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final api = context.read<ApiClient>();
      await api.patch('/api/admin/offers', body: {'id': item['id'], 'status': 'archived'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت الأرشفة'), backgroundColor: AppTheme.success));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: ${e.toString()}'), backgroundColor: AppTheme.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
          ? const LoadingView(message: 'جارٍ تحميل العروض')
          : _error != null
            ? ErrorView(message: 'تعذّر تحميل العروض', onRetry: _load)
            : _items.isEmpty
              ? EmptyView(message: 'لا توجد عروض. أنشئ عرضًا جديدًا.', icon: Icons.local_offer_outlined, actionLabel: 'إضافة', onAction: () => _openForm())
              : CustomScrollView(slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    sliver: SliverList.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, i) => _OfferCard(item: _items[i], onEdit: () => _openForm(_items[i]), onArchive: () => _archive(_items[i])),
                    ),
                  ),
                ]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('عرض جديد'),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  const _OfferCard({required this.item, required this.onEdit, required this.onArchive});

  @override
  Widget build(BuildContext context) {
    final nameAr = item['nameAr']?.toString() ?? '';
    final descAr = item['descriptionAr']?.toString() ?? '';
    final imageUrl = item['imageUrl'] as String?;
    final discountType = item['discountType']?.toString() ?? 'percentage';
    final discountValue = (item['discountValue'] as num?)?.toDouble() ?? 0;
    final startsAt = item['startsAt'] != null ? DateTime.tryParse(item['startsAt'].toString()) : null;
    final endsAt = item['endsAt'] != null ? DateTime.tryParse(item['endsAt'].toString()) : null;
    final status = item['status']?.toString() ?? 'published';
    final roomTypeIds = (item['roomTypeIds'] as List?)?.cast<String>() ?? const [];
    final isExpired = endsAt != null && endsAt.isBefore(DateTime.now());
    final isUpcoming = startsAt != null && startsAt.isAfter(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 100, height: 100,
                child: Stack(children: [
                  imageUrl != null && imageUrl.isNotEmpty
                    ? HotelNetworkImage(url: imageUrl, aspectRatio: 1, radius: BorderRadius.zero, fit: BoxFit.cover)
                    : Container(color: AppTheme.background, child: const Icon(Icons.local_offer, color: AppTheme.primary)),
                  Positioned(top: 6, right: 6, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(color: AppTheme.danger, borderRadius: BorderRadius.circular(6)),
                    child: Text(discountType == 'percentage' ? '-${discountValue.toStringAsFixed(0)}%' : '-${_fmtMoney(discountValue)}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                  )),
                ]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(nameAr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  StatusBadge(status: status, small: true),
                ]),
                if (descAr.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(descAr, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.date_range, size: 12, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(child: Text(
                    '${startsAt != null ? _fmtDate(startsAt) : '-'} → ${endsAt != null ? _fmtDate(endsAt) : '-'}',
                    style: TextStyle(fontSize: 11, color: isExpired ? AppTheme.danger : (isUpcoming ? AppTheme.info : AppTheme.textSecondary), fontWeight: FontWeight.w600),
                  )),
                ]),
                if (roomTypeIds.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('${roomTypeIds.length} نوع غرف', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ],
                if (isExpired)
                  const Text('منتهي', style: TextStyle(fontSize: 10, color: AppTheme.danger, fontWeight: FontWeight.w700)),
                if (isUpcoming)
                  const Text('قادم', style: TextStyle(fontSize: 10, color: AppTheme.info, fontWeight: FontWeight.w700)),
              ]),
            )),
            Column(children: [
              IconButton(icon: const Icon(Icons.edit_outlined, color: AppTheme.primary, size: 18), onPressed: onEdit, tooltip: 'تعديل', visualDensity: VisualDensity.compact),
              IconButton(icon: const Icon(Icons.archive_outlined, color: AppTheme.warning, size: 18), onPressed: onArchive, tooltip: 'أرشفة', visualDensity: VisualDensity.compact),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _OfferForm extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _OfferForm({this.existing});

  @override
  State<_OfferForm> createState() => _OfferFormState();
}

class _OfferFormState extends State<_OfferForm> {
  final _formKey = GlobalKey<FormState>();
  final _slugCtrl = TextEditingController();
  final _nameArCtrl = TextEditingController();
  final _nameEnCtrl = TextEditingController();
  final _descArCtrl = TextEditingController();
  final _descEnCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _conditionsCtrl = TextEditingController();
  DateTime? _startsAt;
  DateTime? _endsAt;
  String _discountType = 'percentage';
  String _status = 'published';
  List<String> _roomTypeIds = const [];
  List<Map<String, dynamic>> _roomTypes = const [];
  bool _loading = false;
  bool _loadingRt = true;

  @override
  void initState() {
    super.initState();
    _loadRoomTypes();
    if (widget.existing != null) {
      final e = widget.existing!;
      _slugCtrl.text = e['slug']?.toString() ?? '';
      _nameArCtrl.text = e['nameAr']?.toString() ?? '';
      _nameEnCtrl.text = e['nameEn']?.toString() ?? '';
      _descArCtrl.text = e['descriptionAr']?.toString() ?? '';
      _descEnCtrl.text = e['descriptionEn']?.toString() ?? '';
      _imageCtrl.text = e['imageUrl']?.toString() ?? '';
      _valueCtrl.text = (e['discountValue'] as num?)?.toString() ?? '';
      _conditionsCtrl.text = e['conditions']?.toString() ?? '';
      _startsAt = e['startsAt'] != null ? DateTime.tryParse(e['startsAt'].toString()) : null;
      _endsAt = e['endsAt'] != null ? DateTime.tryParse(e['endsAt'].toString()) : null;
      _discountType = e['discountType']?.toString() ?? 'percentage';
      _status = e['status']?.toString() ?? 'published';
      _roomTypeIds = (e['roomTypeIds'] as List?)?.cast<String>().toList() ?? const [];
    } else {
      final now = DateTime.now();
      _startsAt = DateTime(now.year, now.month, now.day);
      _endsAt = DateTime(now.year, now.month, now.day + 30);
    }
  }

  Future<void> _loadRoomTypes() async {
    try {
      final api = context.read<ApiClient>();
      final res = await api.get('/api/admin/room-types');
      final list = res is List ? res : const [];
      setState(() { _roomTypes = list.cast<Map<String, dynamic>>(); _loadingRt = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingRt = false);
    }
  }

  @override
  void dispose() {
    _slugCtrl.dispose(); _nameArCtrl.dispose(); _nameEnCtrl.dispose();
    _descArCtrl.dispose(); _descEnCtrl.dispose(); _imageCtrl.dispose();
    _valueCtrl.dispose(); _conditionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = (isStart ? _startsAt : _endsAt) ?? DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      helpText: isStart ? 'تاريخ البداية' : 'تاريخ النهاية',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppTheme.primary)), child: child!),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startsAt = picked;
        if (_endsAt == null || !_endsAt!.isAfter(picked)) {
          _endsAt = picked.add(const Duration(days: 30));
        }
      } else {
        if (_startsAt != null && (picked.isBefore(_startsAt!) || picked == _startsAt)) {
          _endsAt = _startsAt!.add(const Duration(days: 1));
        } else {
          _endsAt = picked;
        }
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startsAt == null || _endsAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدد تاريخي البداية والنهاية')));
      return;
    }
    setState(() => _loading = true);
    try {
      final api = context.read<ApiClient>();
      final body = <String, dynamic>{
        'slug': _slugCtrl.text.trim(),
        'nameAr': _nameArCtrl.text.trim(),
        'nameEn': _nameEnCtrl.text.trim(),
        'descriptionAr': _descArCtrl.text.trim(),
        'descriptionEn': _descEnCtrl.text.trim(),
        'imageUrl': _imageCtrl.text.trim(),
        'startsAt': _startsAt!.toIso8601String(),
        'endsAt': _endsAt!.toIso8601String(),
        'discountType': _discountType,
        'discountValue': double.tryParse(_valueCtrl.text) ?? 0,
        'conditions': _conditionsCtrl.text.trim(),
        'status': _status,
        'roomTypeIds': _roomTypeIds,
      };
      if (widget.existing != null) {
        body['id'] = widget.existing!['id'];
        await api.patch('/api/admin/offers', body: body);
      } else {
        await api.post('/api/admin/offers', body: body);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.existing != null ? 'تم التحديث' : 'تم الإنشاء'), backgroundColor: AppTheme.success));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: ${e.toString()}'), backgroundColor: AppTheme.danger));
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
        decoration: const BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 12), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(children: [
                Icon(widget.existing != null ? Icons.edit : Icons.add_circle, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(widget.existing != null ? 'تعديل عرض' : 'عرض جديد', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  TextFormField(controller: _slugCtrl, decoration: const InputDecoration(labelText: 'المعرّف (slug) *', prefixIcon: Icon(Icons.tag)), validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null),
                  const SizedBox(height: 12),
                  TextFormField(controller: _nameArCtrl, decoration: const InputDecoration(labelText: 'الاسم بالعربية *', prefixIcon: Icon(Icons.title)), validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null),
                  const SizedBox(height: 12),
                  TextFormField(controller: _nameEnCtrl, decoration: const InputDecoration(labelText: 'الاسم بالإنجليزية *', prefixIcon: Icon(Icons.title_outlined)), validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null),
                  const SizedBox(height: 12),
                  TextFormField(controller: _descArCtrl, decoration: const InputDecoration(labelText: 'الوصف بالعربية'), maxLines: 2),
                  const SizedBox(height: 12),
                  TextFormField(controller: _descEnCtrl, decoration: const InputDecoration(labelText: 'الوصف بالإنجليزية'), maxLines: 2),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: InkWell(onTap: () => _pickDate(isStart: true), child: InputDecorator(decoration: const InputDecoration(labelText: 'البداية', prefixIcon: Icon(Icons.play_arrow_outlined)), child: Text(_startsAt == null ? '-' : _fmtDate(_startsAt!), style: const TextStyle(fontSize: 13))))),
                    const SizedBox(width: 10),
                    Expanded(child: InkWell(onTap: () => _pickDate(isStart: false), child: InputDecorator(decoration: const InputDecoration(labelText: 'النهاية', prefixIcon: Icon(Icons.stop_outlined)), child: Text(_endsAt == null ? '-' : _fmtDate(_endsAt!), style: const TextStyle(fontSize: 13))))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: DropdownButtonFormField<String>(
                      value: _discountType,
                      decoration: const InputDecoration(labelText: 'نوع الخصم', prefixIcon: Icon(Icons.percent_outlined)),
                      items: const [
                        DropdownMenuItem(value: 'percentage', child: Text('نسبة مئوية %')),
                        DropdownMenuItem(value: 'fixed', child: Text('مبلغ ثابت')),
                      ],
                      onChanged: (v) => setState(() => _discountType = v ?? 'percentage'),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: TextFormField(
                      controller: _valueCtrl,
                      decoration: InputDecoration(labelText: 'القيمة *', prefixIcon: const Icon(Icons.attach_money), suffixText: _discountType == 'percentage' ? '%' : kCurrencySymbol),
                      keyboardType: TextInputType.number,
                      validator: (v) { final n = double.tryParse(v ?? ''); if (n == null || n <= 0) return 'قيمة غير صحيحة'; return null; },
                    )),
                  ]),
                  const SizedBox(height: 12),
                  TextFormField(controller: _imageCtrl, decoration: const InputDecoration(labelText: 'رابط الصورة', prefixIcon: Icon(Icons.link_outlined))),
                  const SizedBox(height: 12),
                  TextFormField(controller: _conditionsCtrl, decoration: const InputDecoration(labelText: 'الشروط (اختياري)', prefixIcon: Icon(Icons.rule_outlined)), maxLines: 2),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(labelText: 'الحالة', prefixIcon: Icon(Icons.flag_outlined)),
                    items: const [
                      DropdownMenuItem(value: 'published', child: Text('منشور')),
                      DropdownMenuItem(value: 'hidden', child: Text('مخفي')),
                      DropdownMenuItem(value: 'archived', child: Text('مؤرشف')),
                    ],
                    onChanged: (v) => setState(() => _status = v ?? 'published'),
                  ),
                  const SizedBox(height: 12),
                  const Text('أنواع الغرف المشمولة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  if (_loadingRt)
                    const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)))
                  else
                    Wrap(spacing: 6, runSpacing: 6, children: _roomTypes.map((rt) {
                      final id = rt['id']?.toString() ?? '';
                      final name = rt['nameAr']?.toString() ?? '';
                      final active = _roomTypeIds.contains(id);
                      return FilterChip(
                        label: Text(name),
                        selected: active,
                        onSelected: (v) => setState(() {
                          if (v) {
                            _roomTypeIds = [..._roomTypeIds, id];
                          } else {
                            _roomTypeIds = _roomTypeIds.where((e) => e != id).toList();
                          }
                        }),
                        selectedColor: AppTheme.primary,
                        labelStyle: TextStyle(color: active ? Colors.white : AppTheme.textPrimary, fontSize: 11),
                      );
                    }).toList()),
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
                  child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(widget.existing != null ? 'حفظ' : 'إنشاء'),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

String _fmtMoney(num amount) {
  final s = amount.toStringAsFixed(amount == amount.truncateToDouble() ? 0 : 2);
  return '$s $kCurrencySymbol';
}

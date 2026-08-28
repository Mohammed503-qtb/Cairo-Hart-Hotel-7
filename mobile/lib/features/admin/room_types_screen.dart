import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/config.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';

/// Admin room types — CRUD list with image, price, capacity, status.
class AdminRoomTypesScreen extends StatefulWidget {
  const AdminRoomTypesScreen({super.key});
  @override
  State<AdminRoomTypesScreen> createState() => _AdminRoomTypesScreenState();
}

class _AdminRoomTypesScreenState extends State<AdminRoomTypesScreen> {
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
      final res = await api.get('/api/admin/room-types');
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
      builder: (_) => _RoomTypeForm(existing: existing),
    );
    if (result == true) _load();
  }

  Future<void> _confirmArchive(Map<String, dynamic> item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('أرشفة نوع غرفة'),
        content: Text('سيتم تغيير حالة "${item['nameAr']}" إلى "مؤرشف". هل أنت متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('أرشفة')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final api = context.read<ApiClient>();
      await api.patch('/api/admin/room-types', body: {'id': item['id'], 'status': 'archived'});
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
    final isWide = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
          ? const LoadingView(message: 'جارٍ تحميل أنواع الغرف')
          : _error != null
            ? ErrorView(message: 'تعذّر تحميل الأنواع', onRetry: _load)
            : _items.isEmpty
              ? EmptyView(message: 'لا توجد أنواع غرف. أضف نوعًا جديدًا.', icon: Icons.category_outlined, actionLabel: 'إضافة', onAction: () => _openForm())
              : CustomScrollView(slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    sliver: SliverList.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, i) => _RoomTypeCard(
                        item: _items[i],
                        isWide: isWide,
                        onEdit: () => _openForm(_items[i]),
                        onArchive: () => _confirmArchive(_items[i]),
                      ),
                    ),
                  ),
                ]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('نوع جديد'),
      ),
    );
  }
}

class _RoomTypeCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isWide;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  const _RoomTypeCard({required this.item, required this.isWide, required this.onEdit, required this.onArchive});

  @override
  Widget build(BuildContext context) {
    final nameAr = item['nameAr']?.toString() ?? '';
    final nameEn = item['nameEn']?.toString() ?? '';
    final basePrice = (item['basePrice'] as num?)?.toDouble() ?? 0;
    final currency = item['currency']?.toString() ?? kDefaultCurrency;
    final capacity = item['capacity']?.toString() ?? '2';
    final beds = item['beds']?.toString() ?? '';
    final size = item['size'];
    final imageUrl = item['imageUrl'] as String?;
    final status = item['status']?.toString() ?? 'published';
    final roomsCount = item['roomsCount']?.toString() ?? '0';
    final amenities = (item['amenities'] as List?)?.cast<String>() ?? const [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: isWide
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(borderRadius: BorderRadius.circular(12), child: HotelNetworkImage(url: imageUrl, aspectRatio: 4/3, radius: BorderRadius.circular(12))),
              const SizedBox(width: 12),
              Expanded(child: _buildDetails(nameAr, nameEn, basePrice, currency, capacity, beds, size, status, roomsCount, amenities)),
              _buildActions(),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(borderRadius: BorderRadius.circular(12), child: HotelNetworkImage(url: imageUrl, aspectRatio: 16/9, radius: BorderRadius.circular(12))),
              Padding(padding: const EdgeInsets.all(8), child: _buildDetails(nameAr, nameEn, basePrice, currency, capacity, beds, size, status, roomsCount, amenities)),
              _buildActions(),
            ]),
      ),
    );
  }

  Widget _buildDetails(String nameAr, String nameEn, double basePrice, String currency, String capacity, String beds, dynamic size, String status, String roomsCount, List<String> amenities) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(nameAr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis)),
        StatusBadge(status: status, small: true),
      ]),
      const SizedBox(height: 2),
      Text(nameEn, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 6, children: [
        _infoChip(Icons.payments_outlined, _fmtMoney(basePrice, currency)),
        _infoChip(Icons.people_outline, '$capacity ضيف'),
        _infoChip(Icons.bed_outlined, beds),
        if (size != null) _infoChip(Icons.straighten, '$size م²'),
        _infoChip(Icons.home_outlined, '$roomsCount غرف'),
      ]),
      if (amenities.isNotEmpty) ...[
        const SizedBox(height: 6),
        Wrap(spacing: 4, runSpacing: 4, children: amenities.take(4).map((a) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(4)),
          child: Text(a, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        )).toList()),
      ],
    ]);
  }

  Widget _infoChip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(6)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: AppTheme.primary),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _buildActions() => Padding(
    padding: const EdgeInsets.all(4),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(icon: const Icon(Icons.edit_outlined, color: AppTheme.primary), onPressed: onEdit, tooltip: 'تعديل'),
      IconButton(icon: const Icon(Icons.archive_outlined, color: AppTheme.warning), onPressed: onArchive, tooltip: 'أرشفة'),
    ]),
  );
}

class _RoomTypeForm extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _RoomTypeForm({this.existing});

  @override
  State<_RoomTypeForm> createState() => _RoomTypeFormState();
}

class _RoomTypeFormState extends State<_RoomTypeForm> {
  final _formKey = GlobalKey<FormState>();
  final _slugCtrl = TextEditingController();
  final _nameArCtrl = TextEditingController();
  final _nameEnCtrl = TextEditingController();
  final _descArCtrl = TextEditingController();
  final _descEnCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController(text: '2');
  final _bedsCtrl = TextEditingController(text: '1 Double');
  final _sizeCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  String _status = 'published';
  List<String> _amenities = const [];
  bool _loading = false;

  static const _allAmenities = <String>[
    'wifi', 'ac', 'tv', 'minibar', 'safe', 'breakfast', 'parking', 'pool', 'gym', 'spa', 'balcony', 'view', 'kitchen', 'laundry', 'room_service',
  ];

  static const _amenityLabels = <String, String>{
    'wifi': 'واي فاي', 'ac': 'تكييف', 'tv': 'تلفاز', 'minibar': 'ميني بار', 'safe': 'خزنة', 'breakfast': 'فطور', 'parking': 'موقف', 'pool': 'مسبح', 'gym': 'نادي', 'spa': 'سبا', 'balcony': 'شرفة', 'view': 'إطلالة', 'kitchen': 'مطبخ', 'laundry': 'مغسلة', 'room_service': 'خدمة الغرف',
  };

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _slugCtrl.text = e['slug']?.toString() ?? '';
      _nameArCtrl.text = e['nameAr']?.toString() ?? '';
      _nameEnCtrl.text = e['nameEn']?.toString() ?? '';
      _descArCtrl.text = e['descriptionAr']?.toString() ?? '';
      _descEnCtrl.text = e['descriptionEn']?.toString() ?? '';
      _priceCtrl.text = (e['basePrice'] as num?)?.toString() ?? '';
      _capacityCtrl.text = e['capacity']?.toString() ?? '2';
      _bedsCtrl.text = e['beds']?.toString() ?? '';
      _sizeCtrl.text = e['size']?.toString() ?? '';
      _imageCtrl.text = e['imageUrl']?.toString() ?? '';
      _status = e['status']?.toString() ?? 'published';
      _amenities = (e['amenities'] as List?)?.cast<String>().toList() ?? const [];
    }
  }

  @override
  void dispose() {
    _slugCtrl.dispose(); _nameArCtrl.dispose(); _nameEnCtrl.dispose();
    _descArCtrl.dispose(); _descEnCtrl.dispose(); _priceCtrl.dispose();
    _capacityCtrl.dispose(); _bedsCtrl.dispose(); _sizeCtrl.dispose(); _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final api = context.read<ApiClient>();
      final body = <String, dynamic>{
        'slug': _slugCtrl.text.trim(),
        'nameAr': _nameArCtrl.text.trim(),
        'nameEn': _nameEnCtrl.text.trim(),
        'descriptionAr': _descArCtrl.text.trim(),
        'descriptionEn': _descEnCtrl.text.trim(),
        'basePrice': double.tryParse(_priceCtrl.text) ?? 0,
        'capacity': int.tryParse(_capacityCtrl.text) ?? 2,
        'beds': _bedsCtrl.text.trim(),
        'size': double.tryParse(_sizeCtrl.text),
        'amenities': _amenities,
        'imageUrl': _imageCtrl.text.trim(),
        'status': _status,
      };
      if (widget.existing != null) {
        body['id'] = widget.existing!['id'];
        await api.patch('/api/admin/room-types', body: body);
      } else {
        await api.post('/api/admin/room-types', body: body);
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
                Expanded(child: Text(widget.existing != null ? 'تعديل نوع غرفة' : 'نوع غرفة جديد', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
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
                    Expanded(child: TextFormField(controller: _priceCtrl, decoration: const InputDecoration(labelText: 'السعر *', prefixIcon: Icon(Icons.payments_outlined)), keyboardType: TextInputType.number, validator: (v) { final n = double.tryParse(v ?? ''); if (n == null || n < 0) return 'سعر غير صحيح'; return null; })),
                    const SizedBox(width: 10),
                    Expanded(child: TextFormField(controller: _capacityCtrl, decoration: const InputDecoration(labelText: 'السعة'), keyboardType: TextInputType.number)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextFormField(controller: _bedsCtrl, decoration: const InputDecoration(labelText: 'الأسرة', prefixIcon: Icon(Icons.bed_outlined)))),
                    const SizedBox(width: 10),
                    Expanded(child: TextFormField(controller: _sizeCtrl, decoration: const InputDecoration(labelText: 'المساحة م²', prefixIcon: Icon(Icons.straighten_outlined)), keyboardType: TextInputType.number)),
                  ]),
                  const SizedBox(height: 12),
                  TextFormField(controller: _imageCtrl, decoration: const InputDecoration(labelText: 'رابط الصورة', prefixIcon: Icon(Icons.link_outlined))),
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
                  const Text('المرافق', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 6, children: _allAmenities.map((a) {
                    final active = _amenities.contains(a);
                    return FilterChip(
                      label: Text(_amenityLabels[a] ?? a),
                      selected: active,
                      onSelected: (v) => setState(() {
                        if (v) {
                          _amenities = [..._amenities, a];
                        } else {
                          _amenities = _amenities.where((e) => e != a).toList();
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

String _fmtMoney(num amount, [String currency = kCurrencySymbol]) {
  final s = amount.toStringAsFixed(amount == amount.truncateToDouble() ? 0 : 2);
  return '$s $currency';
}

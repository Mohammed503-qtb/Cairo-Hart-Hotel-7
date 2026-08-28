import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/config.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';

/// Admin services — CRUD list with image, price, category, status.
class AdminServicesScreen extends StatefulWidget {
  const AdminServicesScreen({super.key});
  @override
  State<AdminServicesScreen> createState() => _AdminServicesScreenState();
}

class _AdminServicesScreenState extends State<AdminServicesScreen> {
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
      final res = await api.get('/api/admin/services');
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
      builder: (_) => _ServiceForm(existing: existing),
    );
    if (result == true) _load();
  }

  Future<void> _archive(Map<String, dynamic> item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('أرشفة خدمة'),
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
      await api.patch('/api/admin/services', body: {'id': item['id'], 'status': 'archived'});
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
          ? const LoadingView(message: 'جارٍ تحميل الخدمات')
          : _error != null
            ? ErrorView(message: 'تعذّر تحميل الخدمات', onRetry: _load)
            : _items.isEmpty
              ? EmptyView(message: 'لا توجد خدمات. أضف خدمة جديدة.', icon: Icons.room_service_outlined, actionLabel: 'إضافة', onAction: () => _openForm())
              : CustomScrollView(slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    sliver: isWide
                      ? SliverGrid(
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 320, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.6),
                          delegate: SliverChildBuilderDelegate(
                            childCount: _items.length,
                            (context, i) => _ServiceCard(item: _items[i], onEdit: () => _openForm(_items[i]), onArchive: () => _archive(_items[i])),
                          ),
                        )
                      : SliverList.builder(itemCount: _items.length, itemBuilder: (context, i) => _ServiceCard(item: _items[i], onEdit: () => _openForm(_items[i]), onArchive: () => _archive(_items[i]))),
                  ),
                ]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('خدمة جديدة'),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  const _ServiceCard({required this.item, required this.onEdit, required this.onArchive});

  @override
  Widget build(BuildContext context) {
    final nameAr = item['nameAr']?.toString() ?? '';
    final nameEn = item['nameEn']?.toString() ?? '';
    final price = (item['price'] as num?)?.toDouble() ?? 0;
    final category = item['category']?.toString() ?? 'general';
    final status = item['status']?.toString() ?? 'published';
    final imageUrl = item['imageUrl'] as String?;
    final descAr = item['descriptionAr'] as String? ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(12)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl != null && imageUrl.isNotEmpty
                  ? HotelNetworkImage(url: imageUrl, aspectRatio: 1, radius: BorderRadius.zero, fit: BoxFit.cover)
                  : const Icon(Icons.room_service, color: AppTheme.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(nameAr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis)),
                StatusBadge(status: status, small: true),
              ]),
              const SizedBox(height: 2),
              Text(nameEn, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              if (descAr.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(descAr, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 4, children: [
                _chip(Icons.category_outlined, _categoryLabel(category)),
                _chip(Icons.payments_outlined, _fmtMoney(price)),
              ]),
            ])),
            Column(children: [
              IconButton(icon: const Icon(Icons.edit_outlined, color: AppTheme.primary, size: 18), onPressed: onEdit, tooltip: 'تعديل', visualDensity: VisualDensity.compact),
              IconButton(icon: const Icon(Icons.archive_outlined, color: AppTheme.warning, size: 18), onPressed: onArchive, tooltip: 'أرشفة', visualDensity: VisualDensity.compact),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 10, color: AppTheme.primary),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w700)),
    ]),
  );
}

class _ServiceForm extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _ServiceForm({this.existing});

  @override
  State<_ServiceForm> createState() => _ServiceFormState();
}

class _ServiceFormState extends State<_ServiceForm> {
  final _formKey = GlobalKey<FormState>();
  final _slugCtrl = TextEditingController();
  final _nameArCtrl = TextEditingController();
  final _nameEnCtrl = TextEditingController();
  final _descArCtrl = TextEditingController();
  final _descEnCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  String _category = 'general';
  String _status = 'published';
  bool _loading = false;

  final _categories = const [
    ('general', 'عام'),
    ('cleaning', 'تنظيف'),
    ('food', 'طعام وشراب'),
    ('maintenance', 'صيانة'),
    ('transport', 'نقل'),
    ('laundry', 'مغسلة'),
    ('other', 'أخرى'),
  ];

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
      _priceCtrl.text = (e['price'] as num?)?.toString() ?? '';
      _imageCtrl.text = e['imageUrl']?.toString() ?? '';
      _category = e['category']?.toString() ?? 'general';
      _status = e['status']?.toString() ?? 'published';
    }
  }

  @override
  void dispose() {
    _slugCtrl.dispose(); _nameArCtrl.dispose(); _nameEnCtrl.dispose();
    _descArCtrl.dispose(); _descEnCtrl.dispose(); _priceCtrl.dispose(); _imageCtrl.dispose();
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
        'price': double.tryParse(_priceCtrl.text) ?? 0,
        'category': _category,
        'imageUrl': _imageCtrl.text.trim(),
        'status': _status,
      };
      if (widget.existing != null) {
        body['id'] = widget.existing!['id'];
        await api.patch('/api/admin/services', body: body);
      } else {
        await api.post('/api/admin/services', body: body);
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
                Expanded(child: Text(widget.existing != null ? 'تعديل خدمة' : 'خدمة جديدة', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
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
                  TextFormField(controller: _priceCtrl, decoration: const InputDecoration(labelText: 'السعر *', prefixIcon: Icon(Icons.payments_outlined), suffixText: kCurrencySymbol), keyboardType: TextInputType.number, validator: (v) { final n = double.tryParse(v ?? ''); if (n == null || n < 0) return 'سعر غير صحيح'; return null; }),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(labelText: 'التصنيف', prefixIcon: Icon(Icons.category_outlined)),
                    items: _categories.map((c) => DropdownMenuItem(value: c.$1, child: Text(c.$2))).toList(),
                    onChanged: (v) => setState(() => _category = v ?? 'general'),
                  ),
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

String _fmtMoney(num amount) {
  final s = amount.toStringAsFixed(amount == amount.truncateToDouble() ? 0 : 2);
  return '$s $kCurrencySymbol';
}

String _categoryLabel(String category) {
  const map = <String, String>{
    'cleaning': 'تنظيف', 'food': 'طعام', 'maintenance': 'صيانة',
    'transport': 'نقل', 'laundry': 'مغسلة', 'general': 'عام', 'other': 'أخرى',
  };
  return map[category.toLowerCase()] ?? category;
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/config.dart';
import '../../core/models.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});
  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  List<Service>? _services;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = context.read<ApiClient>();
      final json = await api.get('/api/public/home') as Map<String, dynamic>;
      final list = json['services'] as List? ?? [];
      setState(() { _services = list.map((e) => Service.fromJson(e as Map<String, dynamic>)).toList(); _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الخدمات'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [Tab(text: 'الخدمات المتاحة', icon: Icon(Icons.grid_view_outlined)), Tab(text: 'طلباتي', icon: Icon(Icons.history))],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildServicesTab(),
          const _ServiceRequestsLookup(),
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    if (_loading) return const LoadingView(message: 'جارٍ تحميل الخدمات');
    if (_error != null) return ErrorView(message: 'تعذّر تحميل الخدمات', onRetry: _load);
    if (_services == null || _services!.isEmpty) {
      return EmptyView(
        message: 'لا توجد خدمات متاحة حاليًا',
        icon: Icons.room_service_outlined,
        actionLabel: 'إعادة المحاولة',
        onAction: _load,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth > 720 ? 3 : (c.maxWidth > 480 ? 2 : 1);
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: cols == 1 ? 1.9 : 0.82,
          ),
          itemCount: _services!.length,
          itemBuilder: (context, i) => _ServiceCard(service: _services![i]),
        );
      }),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Service service;
  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiClient>();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showRequestDialog(context, api),
        child: LayoutBuilder(builder: (context, c) {
          if (c.maxWidth < 280) {
            return Row(children: [
              SizedBox(width: 90, height: 90, child: HotelNetworkImage(url: service.imageUrl, radius: BorderRadius.zero, fit: BoxFit.cover)),
              const SizedBox(width: 12),
              Expanded(child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(service.nameAr, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(_categoryLabel(service.category), style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  const Spacer(),
                  Row(children: [
                    Text(service.price > 0 ? _fmtPrice(service.price, service.imageUrl) : 'مجاني', style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary, fontSize: 13)),
                    const Spacer(),
                    const Icon(Icons.add_circle, color: AppTheme.primary, size: 20),
                  ]),
                ]),
              )),
            ]);
          }
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            HotelNetworkImage(url: service.imageUrl, aspectRatio: 1.4, radius: BorderRadius.zero),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_categoryLabel(service.category), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                ),
                const SizedBox(height: 8),
                Text(service.nameAr, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (service.descriptionAr != null && service.descriptionAr!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(service.descriptionAr!, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 8),
                Row(children: [
                  Text(service.price > 0 ? _fmtPrice(service.price) : 'مجاني', style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary, fontSize: 13)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(20)),
                    child: const Text('اطلب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ]),
              ]),
            ),
          ]);
        }),
      ),
    );
  }

  String _fmtPrice(double amount, [String? _]) => '${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)} $kCurrencySymbol';

  void _showRequestDialog(BuildContext context, ApiClient api) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ServiceRequestSheet(service: service, api: api),
    );
  }
}

class _ServiceRequestSheet extends StatefulWidget {
  final Service service;
  final ApiClient api;
  const _ServiceRequestSheet({required this.service, required this.api});

  @override
  State<_ServiceRequestSheet> createState() => _ServiceRequestSheetState();
}

class _ServiceRequestSheetState extends State<_ServiceRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _priority = 'normal';
  bool _submitting = false;
  String? _resultRef;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _submitting = true; _resultRef = null; });
    try {
      final res = await widget.api.post('/api/service-requests', body: {
        'guestName': _nameCtrl.text.trim(),
        'guestPhone': _phoneCtrl.text.trim(),
        'serviceId': widget.service.id,
        'category': widget.service.category,
        'description': _descCtrl.text.trim(),
        'priority': _priority,
      }) as Map<String, dynamic>;
      setState(() { _resultRef = res['reference'] as String?; });
      _nameCtrl.clear();
      _phoneCtrl.clear();
      _descCtrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: ${e.toString()}'), backgroundColor: AppTheme.danger));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + keyboard),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                const Spacer(),
                IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.room_service, color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('طلب: ${widget.service.nameAr}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  Text('التصنيف: ${_categoryLabel(widget.service.category)}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ])),
              ]),
              const SizedBox(height: 16),
              if (_resultRef != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.success.withValues(alpha: 0.3))),
                  child: Column(children: [
                    const Icon(Icons.check_circle, color: AppTheme.success, size: 32),
                    const SizedBox(height: 8),
                    const Text('تم إرسال طلبك بنجاح', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.success)),
                    const SizedBox(height: 4),
                    Text('رقم الطلب: $_resultRef', style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                  ]),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إغلاق'))),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(onPressed: () { Navigator.of(context).pop(); }, child: const Text('تم'))),
                ]),
              ] else ...[
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'الاسم', prefixIcon: Icon(Icons.person_outline)),
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone_outlined)),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'الهاتف مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(labelText: 'تفاصيل الطلب *', alignLabelWithHint: true, prefixIcon: Icon(Icons.description_outlined)),
                  maxLines: 3,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'الوصف مطلوب' : null,
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Text('الأولوية:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(width: 12),
                  ChoiceChip(label: const Text('عادية'), selected: _priority == 'normal', onSelected: (_) => setState(() => _priority = 'normal')),
                  const SizedBox(width: 8),
                  ChoiceChip(label: const Text('عاجلة'), selected: _priority == 'urgent', onSelected: (_) => setState(() => _priority = 'urgent')),
                ]),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
                    label: Text(_submitting ? 'جارٍ الإرسال...' : 'إرسال الطلب'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceRequestsLookup extends StatefulWidget {
  const _ServiceRequestsLookup();
  @override
  State<_ServiceRequestsLookup> createState() => _ServiceRequestsLookupState();
}

class _ServiceRequestsLookupState extends State<_ServiceRequestsLookup> {
  final _phoneCtrl = TextEditingController();
  List<Map<String, dynamic>>? _results;
  bool _loading = false;
  String? _error;
  bool _searched = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل رقم الهاتف')));
      return;
    }
    setState(() { _loading = true; _error = null; _searched = true; });
    try {
      final api = context.read<ApiClient>();
      final res = await api.get('/api/service-requests', query: {'phone': phone});
      final list = res is List ? res : (res is Map && res['data'] is List ? res['data'] as List : const []);
      setState(() { _results = list.cast<Map<String, dynamic>>(); });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone_outlined), hintText: '7XXXXXXXX'),
              keyboardType: TextInputType.phone,
              onSubmitted: (_) => _search(),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(onPressed: _loading ? null : _search, child: const Text('بحث')),
        ]),
      ),
      Expanded(
        child: _loading
          ? const LoadingView(message: 'جارٍ البحث')
          : _error != null
            ? ErrorView(message: 'تعذّر جلب الطلبات', onRetry: _search)
            : (_results == null || _results!.isEmpty)
              ? EmptyView(
                  message: _searched ? 'لا توجد طلبات لهذا الرقم' : 'أدخل رقم هاتفك لعرض طلباتك السابقة',
                  icon: Icons.history,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _results!.length,
                  itemBuilder: (context, i) => _ServiceRequestItem(item: _results![i]),
                ),
      ),
    ]);
  }
}

class _ServiceRequestItem extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ServiceRequestItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final ref = item['reference'] as String? ?? '-';
    final status = item['status'] as String? ?? 'new';
    final category = item['category'] as String? ?? 'general';
    final desc = item['descriptionAr'] as String? ?? '';
    final createdAt = item['createdAt'] as String?;
    final completedAt = item['completedAt'] as String?;
    final service = item['service'] as Map<String, dynamic>?;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.support_agent, color: AppTheme.primary, size: 20),
        ),
        title: Text(ref, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        subtitle: Row(children: [
          StatusBadge(status: status, small: true),
          const SizedBox(width: 8),
          Text(_categoryLabel(category), style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ]),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (service != null) ...[
                _row('الخدمة', service['nameAr']?.toString() ?? '-'),
                _row('السعر', service['price'] != null ? '${service['price']} $kCurrencySymbol' : '-'),
              ],
              _row('التصنيف', _categoryLabel(category)),
              _row('الوصف', desc),
              if (createdAt != null) _row('الإنشاء', createdAt.substring(0, createdAt.length >= 16 ? 16 : createdAt.length)),
              if (completedAt != null) _row('الإنجاز', completedAt.substring(0, completedAt.length >= 16 ? 16 : completedAt.length)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500))),
    ]),
  );
}

String _categoryLabel(String category) {
  const map = <String, String>{
    'cleaning': 'تنظيف',
    'food': 'طعام وشراب',
    'maintenance': 'صيانة',
    'transport': 'نقل',
    'laundry': 'مغسلة',
    'general': 'عام',
    'other': 'أخرى',
  };
  return map[category.toLowerCase()] ?? category;
}

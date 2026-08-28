import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../core/config.dart';
import '../../core/models.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});
  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حجوزاتي وطلباتي'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'الحجوزات', icon: Icon(Icons.bed_outlined)),
            Tab(text: 'طلبات الخدمات', icon: Icon(Icons.room_service_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [_BookingsLookup(), _ServiceRequestsLookup()],
      ),
    );
  }
}

class _BookingsLookup extends StatefulWidget {
  const _BookingsLookup();
  @override
  State<_BookingsLookup> createState() => _BookingsLookupState();
}

class _BookingsLookupState extends State<_BookingsLookup> {
  final _phoneCtrl = TextEditingController();
  List<BookingRequest>? _results;
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
      final res = await api.get('/api/booking-requests', query: {'phone': phone});
      final list = res is List ? res : const [];
      setState(() { _results = list.map((e) => BookingRequest.fromJson(e as Map<String, dynamic>)).toList(); });
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
          ? const LoadingView(message: 'جارٍ البحث عن حجوزاتك')
          : _error != null
            ? ErrorView(message: 'تعذّر جلب الحجوزات', onRetry: _search)
            : (_results == null || _results!.isEmpty)
              ? EmptyView(
                  message: _searched ? 'لا توجد حجوزات لهذا الرقم' : 'أدخل رقم هاتفك لمتابعة طلباتك',
                  icon: Icons.search_off,
                )
              : RefreshIndicator(
                  onRefresh: _search,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _results!.length,
                    itemBuilder: (context, i) => _BookingCard(request: _results![i]),
                  ),
                ),
      ),
    ]);
  }
}

class _BookingCard extends StatelessWidget {
  final BookingRequest request;
  const _BookingCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final rt = request.roomType;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 56, height: 56,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppTheme.background),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: rt?.imageUrl != null
              ? HotelNetworkImage(url: rt!.imageUrl, radius: BorderRadius.zero, fit: BoxFit.cover)
              : const Icon(Icons.bed_outlined, color: AppTheme.primary),
          ),
        ),
        title: Row(children: [
          Text(request.reference, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(width: 8),
          StatusBadge(status: request.status, small: true),
        ]),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${rt?.nameAr ?? 'غرفة غير محددة'} • ${_fmtDate(request.checkIn)} → ${_fmtDate(request.checkOut)} • ${request.nights} ليالٍ',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _row('الغرفة', rt?.nameAr ?? '-'),
              _row('الوصول', _fmtDate(request.checkIn)),
              _row('المغادرة', _fmtDate(request.checkOut)),
              _row('عدد الليالي', request.nights.toString()),
              _row('البالغين', request.adults.toString()),
              _row('الأطفال', request.children.toString()),
              _row('الاسم', request.guestName),
              _row('الهاتف', request.guestPhone),
              _row('القناة', _channelLabel(request.channel)),
              _row('تاريخ الطلب', _fmtDateTime(request.createdAt)),
              if (request.message != null && request.message!.isNotEmpty) _row('ملاحظات', request.message!),
              const Divider(height: 16),
              if (request.reservation != null) ...[
                const Text('الحجز المؤكد', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.success, fontSize: 13)),
                const SizedBox(height: 6),
                _row('رقم التأكيد', request.reservation!.confirmationNo ?? '-'),
                _row('حالة الحجز', statusLabelAr(request.reservation!.bookingStatus ?? request.status)),
                _row('حالة الدفع', statusLabelAr(request.reservation!.paymentStatus ?? 'unpaid')),
                if (request.reservation!.total != null)
                  _row('الإجمالي', '${request.reservation!.total!.toStringAsFixed(2)} $kCurrencySymbol'),
                if (request.reservation!.paid != null)
                  _row('المدفوع', '${request.reservation!.paid!.toStringAsFixed(2)} $kCurrencySymbol'),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    const Icon(Icons.info_outline, color: AppTheme.warning, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      'طلبك قيد المراجعة. سيتواصل معك الفريق لتأكيد الحجز عبر واتساب.',
                      style: TextStyle(fontSize: 12, color: AppTheme.warning, fontWeight: FontWeight.w600),
                    )),
                  ]),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openWhatsapp(context),
                  icon: const Icon(Icons.chat_outlined, color: Color(0xFF25D366)),
                  label: const Text('تواصل عبر واتساب'),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF25D366), side: const BorderSide(color: Color(0xFF25D366))),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Future<void> _openWhatsapp(BuildContext context) async {
    try {
      final api = context.read<ApiClient>();
      final res = await api.post('/api/whatsapp/link', body: {
        'guestName': request.guestName,
        'guestPhone': request.guestPhone,
        'bookingRef': request.reference,
        'roomTypeNameAr': request.roomType?.nameAr,
        'checkIn': _fmtDate(request.checkIn),
        'checkOut': _fmtDate(request.checkOut),
        'adults': request.adults,
        'children': request.children,
        'nights': request.nights,
      }) as Map<String, dynamic>;
      final url = res['url'] as String?;
      if (url == null) throw 'لا يوجد رابط';
      if (!context.mounted) return;
      final uri = Uri.parse(url);
      final ok = await _launchUri(uri);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر فتح واتساب')));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: ${e.toString()}')));
    }
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500))),
    ]),
  );
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
      final list = res is List ? res : const [];
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
              decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone_outlined)),
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
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(children: [
            StatusBadge(status: status, small: true),
            const SizedBox(width: 8),
            Text(_categoryLabel(category), style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ]),
        ),
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
              if (createdAt != null) _row('الإنشاء', _fmtDateTime(DateTime.tryParse(createdAt) ?? DateTime.now())),
              if (completedAt != null) _row('الإنجاز', _fmtDateTime(DateTime.tryParse(completedAt) ?? DateTime.now())),
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

Future<bool> _launchUri(Uri uri) async {
  try {
    final can = await canLaunchUrl(uri);
    if (!can) return false;
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    return launched;
  } catch (_) {
    return false;
  }
}

String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

String _fmtDateTime(DateTime d) =>
  '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';

String _channelLabel(String c) => const {'app': 'تطبيق', 'whatsapp': 'واتساب', 'phone': 'هاتف', 'web': 'موقع'}[c.toLowerCase()] ?? c;

String _categoryLabel(String category) {
  const map = <String, String>{
    'cleaning': 'تنظيف', 'food': 'طعام وشراب', 'maintenance': 'صيانة',
    'transport': 'نقل', 'laundry': 'مغسلة', 'general': 'عام', 'other': 'أخرى',
  };
  return map[category.toLowerCase()] ?? category;
}

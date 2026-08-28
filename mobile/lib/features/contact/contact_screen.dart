import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../core/config.dart';
import '../../core/models.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';

/// Contact screen — hotel info + WhatsApp/Call buttons + contact form + policies.
class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiClient>();
    return Scaffold(
      appBar: AppBar(title: const Text('تواصل معنا')),
      body: FutureBuilder(
        future: api.get('/api/public/home'),
        builder: (context, AsyncSnapshot<dynamic> snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingView(message: 'جارٍ تحميل المعلومات');
          }
          if (snap.hasError || snap.data is! Map) {
            return ErrorView(
              message: 'تعذّر تحميل المعلومات',
              onRetry: () => Navigator.of(context).pushReplacementNamed('/contact'),
            );
          }
          final data = Map<String, dynamic>.from(snap.data as Map);
          final settings = HotelSettings.fromJson(Map<String, dynamic>.from(data['settings'] ?? const {}));
          return _ContactBody(settings: settings, api: api);
        },
      ),
    );
  }
}

class _ContactBody extends StatefulWidget {
  final HotelSettings settings;
  final ApiClient api;
  const _ContactBody({required this.settings, required this.api});

  @override
  State<_ContactBody> createState() => _ContactBodyState();
}

class _ContactBodyState extends State<_ContactBody> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _submitting = false;
  String? _resultRef;
  String? _resultWhatsappUrl;
  bool _policiesExpanded = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر فتح الرابط')));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _submitting = true; _resultRef = null; _resultWhatsappUrl = null; });
    try {
      final res = await widget.api.post('/api/contact', body: {
        'guestName': _nameCtrl.text.trim(),
        'guestPhone': _phoneCtrl.text.trim(),
        'channel': 'whatsapp',
        'subject': _subjectCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
      }) as Map<String, dynamic>;
      setState(() {
        _resultRef = res['reference'] as String?;
        _resultWhatsappUrl = res['whatsappUrl'] as String?;
      });
      _nameCtrl.clear();
      _phoneCtrl.clear();
      _subjectCtrl.clear();
      _messageCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال طلبك بنجاح ✓'), backgroundColor: AppTheme.success),
        );
      }
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
    final s = widget.settings;
    final whatsappNum = (s.whatsapp ?? kDefaultWhatsapp).replaceAll(RegExp(r'[^0-9]'), '');
    final phone = s.phone ?? '';
    final mapsUrl = s.values['hotel.maps_url'] ?? 'https://maps.google.com/?q=${Uri.encodeComponent(s.addressAr ?? 'Cairo Heart Hotel')}';
    final cancellation = s.values['cancellation.policy_ar'];
    final checkin = s.checkinTime ?? '14:00';
    final checkout = s.checkoutTime ?? '12:00';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Big WhatsApp + Call buttons
        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _launch('https://wa.me/$whatsappNum?text=${Uri.encodeQueryComponent('مرحبًا، أرغب في الاستفسار عن خدمات الفندق.')}'),
              icon: const Icon(Icons.chat_outlined),
              label: const Text('واتساب'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: phone.isEmpty ? null : () => _launch('tel:$phone'),
              icon: const Icon(Icons.phone),
              label: const Text('اتصال'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48)),
            ),
          ),
        ]),
        const SizedBox(height: 16),

        // Hotel info card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.contact_page_outlined, color: AppTheme.primary, size: 22),
                SizedBox(width: 8),
                Text('معلومات التواصل', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              ]),
              const SizedBox(height: 12),
              if (s.hotelNameAr != null) _infoRow(Icons.apartment, s.hotelNameAr!),
              if (s.phone != null && s.phone!.isNotEmpty) _infoRow(Icons.phone_outlined, s.phone!),
              if (s.whatsapp != null && s.whatsapp!.isNotEmpty) _infoRow(Icons.chat_outlined, s.whatsapp!),
              if (s.email != null && s.email!.isNotEmpty) _infoRow(Icons.email_outlined, s.email!),
              if (s.addressAr != null && s.addressAr!.isNotEmpty) _infoRow(Icons.location_on_outlined, s.addressAr!),
              _infoRow(Icons.access_time, 'تسجيل الدخول: $checkin | المغادرة: $checkout'),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        // Map link
        Card(
          child: ListTile(
            onTap: () => _launch(mapsUrl),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.info.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.map_outlined, color: AppTheme.info, size: 22),
            ),
            title: const Text('موقعنا على الخريطة', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(s.addressAr ?? 'عدن - اليمن', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            trailing: const Icon(Icons.chevron_left, color: AppTheme.primary),
          ),
        ),
        const SizedBox(height: 16),

        // Contact form
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.mail_outline, color: AppTheme.primary, size: 22),
                  SizedBox(width: 8),
                  Text('أرسل لنا رسالة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                ]),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'الاسم الكامل *', prefixIcon: Icon(Icons.person_outline)),
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
                  controller: _subjectCtrl,
                  decoration: const InputDecoration(labelText: 'الموضوع', prefixIcon: Icon(Icons.subject)),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _messageCtrl,
                  decoration: const InputDecoration(labelText: 'الرسالة *', alignLabelWithHint: true),
                  maxLines: 4,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'الرسالة مطلوبة' : null,
                ),
                const SizedBox(height: 16),
                if (_resultRef != null || _resultWhatsappUrl != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.success.withValues(alpha: 0.3))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.check_circle, color: AppTheme.success, size: 18),
                        const SizedBox(width: 8),
                        Text('تم إرسال طلبك — رقم: ${_resultRef ?? '-'}', style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.w700)),
                      ]),
                      if (_resultWhatsappUrl != null) ...[
                        const SizedBox(height: 8),
                        const Text('اضغط للمتابعة عبر واتساب:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => _launch(_resultWhatsappUrl!),
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text('فتح واتساب'),
                          ),
                        ),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send),
                    label: Text(_submitting ? 'جارٍ الإرسال...' : 'إرسال'),
                  ),
                ),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Policies accordion
        Card(
          child: ExpansionTile(
            initiallyExpanded: _policiesExpanded,
            onExpansionChanged: (v) => setState(() => _policiesExpanded = v),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: const Icon(Icons.policy_outlined, color: AppTheme.primary),
            title: const Text('سياسات الفندق', style: TextStyle(fontWeight: FontWeight.w700)),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _policyItem('تسجيل الدخول', 'من الساعة $checkin. يتطلب إثبات هوية.'),
                  const Divider(height: 20),
                  _policyItem('تسجيل المغادرة', 'حتى الساعة $checkout. يمكن طلب تأخير المغادرة حسب التوفر.'),
                  if (cancellation != null && cancellation.isNotEmpty) ...[
                    const Divider(height: 20),
                    _policyItem('سياسة الإلغاء', cancellation),
                  ],
                  const Divider(height: 20),
                  _policyItem('الحجز', 'يتطلب تأكيدًا من الفندق. سنتواصل معك عبر واتساب لتأكيد الحجز.'),
                  const Divider(height: 20),
                  _policyItem('الدفع', 'نقدًا أو تحويلًا بنكيًا عند الوصول. الدفع الإلكتروني قيد التفعيل.'),
                ]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Icon(icon, size: 18, color: AppTheme.textSecondary),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary))),
    ]),
  );

  Widget _policyItem(String title, String body) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary, fontSize: 13)),
      const SizedBox(height: 4),
      Text(body, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.5)),
    ],
  );
}

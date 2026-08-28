import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../core/config.dart';
import '../../core/models.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';

/// 3-step booking flow: review → guest info → confirmation.
class BookingFlowScreen extends StatefulWidget {
  final Map<String, dynamic> args;
  const BookingFlowScreen({super.key, required this.args});

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  int _step = 0;
  bool _submitting = false;
  bool _waLaunching = false;
  Map<String, dynamic>? _result;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _waCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _waCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  RoomType? get _roomType {
    final rt = widget.args['roomType'];
    if (rt is RoomType) return rt;
    if (rt is Map) return RoomType.fromJson(Map<String, dynamic>.from(rt));
    return null;
  }

  DateTime? get _checkIn => _parseDate(widget.args['checkIn']);
  DateTime? get _checkOut => _parseDate(widget.args['checkOut']);
  int get _adults => _toInt(widget.args['adults'], 1);
  int get _children => _toInt(widget.args['children'], 0);
  double get _pricePerNight => _toDouble(widget.args['pricePerNight'], _roomType?.basePrice ?? 0);
  int get _nights => _toInt(widget.args['nights'], 1);
  double get _total => _toDouble(widget.args['total'], _pricePerNight * _nights);
  String get _currency => (widget.args['currency'] as String?) ?? _roomType?.currency ?? 'YER';
  Map<String, dynamic>? get _appliedOffer {
    final v = widget.args['appliedOffer'];
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  double get _subtotal => _pricePerNight * _nights;
  double get _discount => _appliedOffer != null ? (_subtotal - _total) : 0;

  bool get _hasValidArgs => _roomType != null && _checkIn != null && _checkOut != null && _nights >= 1;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final api = context.read<ApiClient>();
      final res = await api.post('/api/booking-requests', body: {
        'roomTypeId': _roomType?.id,
        'checkIn': _fmtIso(_checkIn!),
        'checkOut': _fmtIso(_checkOut!),
        'adults': _adults,
        'children': _children,
        'guestName': _nameCtrl.text.trim(),
        'guestPhone': _phoneCtrl.text.trim(),
        'guestWhatsapp': _waCtrl.text.trim().isEmpty ? null : _waCtrl.text.trim(),
        'message': _msgCtrl.text.trim().isEmpty ? null : _msgCtrl.text.trim(),
        'channel': 'app',
      }) as Map<String, dynamic>;
      setState(() {
        _result = res;
        _step = 2;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: ${e.toString()}'), backgroundColor: AppTheme.danger));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _openWhatsApp() async {
    if (_result == null) return;
    setState(() => _waLaunching = true);
    try {
      final api = context.read<ApiClient>();
      final res = await api.post('/api/whatsapp/link', body: {
        'guestName': _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : (_result!['guestName'] ?? ''),
        'guestPhone': _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : (_result!['guestPhone'] ?? ''),
        'bookingRef': _result!['reference'],
        'roomTypeNameAr': _roomType?.nameAr,
        'checkIn': _checkIn != null ? _fmtIso(_checkIn!) : null,
        'checkOut': _checkOut != null ? _fmtIso(_checkOut!) : null,
        'adults': _adults,
        'children': _children,
        'nights': _nights,
        'message': _msgCtrl.text.trim().isEmpty ? null : _msgCtrl.text.trim(),
      }) as Map<String, dynamic>;
      final url = res['url'] as String?;
      if (url == null) throw 'لا يوجد رابط واتساب';
      final uri = Uri.parse(url);
      final ok = await canLaunchUrl(uri);
      if (ok) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر فتح واتساب')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: ${e.toString()}'), backgroundColor: AppTheme.danger));
      }
    } finally {
      if (mounted) setState(() => _waLaunching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasValidArgs) {
      return Scaffold(
        appBar: AppBar(title: const Text('تأكيد الحجز'), leading: IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back))),
        body: EmptyView(
          message: 'معلومات الحجز غير مكتملة. يرجى اختيار غرفة وتواريخ صحيحة.',
          icon: Icons.warning_amber,
          actionLabel: 'العودة للغرف',
          onAction: () => Navigator.of(context).pushNamedAndRemoveUntil('/rooms', (route) => false),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('تأكيد الحجز'),
        leading: IconButton(onPressed: () {
          if (_step == 0) {
            Navigator.of(context).pop();
          } else if (_step < 2) {
            setState(() => _step = _step - 1);
          } else {
            Navigator.of(context).pushNamedAndRemoveUntil('/bookings', (route) => false);
          }
        }, icon: Icon(_step == 0 ? Icons.arrow_back : Icons.arrow_forward)),
        actions: [
          if (_step == 2) TextButton.icon(
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/bookings', (route) => false),
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('تم'),
          ),
        ],
      ),
      body: Column(
        children: [
          _stepIndicator(),
          Expanded(child: _buildStep()),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _stepIndicator() {
    final labels = ['مراجعة', 'بيانات الضيف', 'تأكيد'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppTheme.surface,
      child: Row(children: List.generate(3, (i) {
        final active = i == _step;
        final done = i < _step;
        final color = done ? AppTheme.success : (active ? AppTheme.primary : AppTheme.textSecondary.withValues(alpha: 0.3));
        return Expanded(child: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: done
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(labels[i], style: TextStyle(color: color, fontSize: 12, fontWeight: active ? FontWeight.w700 : FontWeight.w500))),
          if (i < 2) Container(width: 16, height: 1, color: i < _step ? AppTheme.success : Colors.grey.shade300),
        ]));
      })),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildReviewStep();
      case 1:
        return _buildGuestForm();
      case 2:
        return _buildConfirmation();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildReviewStep() {
    final rt = _roomType!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            HotelNetworkImage(url: rt.imageUrl, aspectRatio: 1.7, radius: BorderRadius.zero),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(rt.nameAr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.people_outline, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text('${rt.capacity} ضيوف', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(width: 12),
                  Icon(Icons.bed_outlined, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(rt.beds, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  if (rt.size != null) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.square_foot, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text('${rt.size} م²', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ]),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        _summaryCard(
          title: 'تفاصيل الإقامة',
          rows: [
            _SummaryRow('الغرفة', rt.nameAr),
            _SummaryRow('الوصول', _fmtArDate(_checkIn!)),
            _SummaryRow('المغادرة', _fmtArDate(_checkOut!)),
            _SummaryRow('عدد الليالي', '$_nights ${_nights == 1 ? 'ليلة' : 'ليالٍ'}'),
            _SummaryRow('البالغون', '$_adults'),
            _SummaryRow('الأطفال', '$_children'),
          ],
        ),
        const SizedBox(height: 12),
        _summaryCard(
          title: 'تفصيل السعر',
          rows: [
            _SummaryRow('سعر الليلة', _fmtMoney(_pricePerNight, _currency)),
            _SummaryRow('عدد الليالي', '$_nights × ${_fmtMoney(_pricePerNight, _currency)}'),
            _SummaryRow('المجموع الفرعي', _fmtMoney(_subtotal, _currency)),
            if (_discount > 0) ...[
              _SummaryRow('الخصم', '- ${_fmtMoney(_discount, _currency)}'),
              if (_appliedOffer != null && _appliedOffer!['nameAr'] != null)
                _SummaryRow('العرض', _appliedOffer!['nameAr'] as String),
            ],
          ],
          total: _SummaryRow('الإجمالي', _fmtMoney(_total, _currency), emphasize: true),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.info.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.info_outline, color: AppTheme.info, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'هذا تقدير سعر. الحجز يتطلب تأكيد الفندق. سيتم التواصل معك عبر واتساب لإتمام الحجز.',
              style: TextStyle(color: AppTheme.info, fontSize: 12, height: 1.4),
            )),
          ]),
        ),
      ],
    );
  }

  Widget _buildGuestForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('بيانات الضيف', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          const Text('سنستخدم هذه البيانات للتواصل معك لتأكيد الحجز', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'الاسم الكامل *', prefixIcon: Icon(Icons.person_outline), hintText: 'مثال: أحمد محمد'),
            textInputAction: TextInputAction.next,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneCtrl,
            decoration: const InputDecoration(labelText: 'رقم الهاتف *', prefixIcon: Icon(Icons.phone_outlined), hintText: '7XXXXXXXX'),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'الهاتف مطلوب';
              if (v.trim().length < 6) return 'رقم هاتف غير صحيح';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _waCtrl,
            decoration: const InputDecoration(labelText: 'رقم واتساب (اختياري)', prefixIcon: Icon(Icons.chat_outlined), hintText: 'للتواصل عبر واتساب'),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _msgCtrl,
            decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)', alignLabelWithHint: true, hintText: 'طلبات خاصة، وقت الوصول المتوقع، إلخ.'),
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          // Mini summary reminder
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.bed, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(
                '${_roomType?.nameAr ?? ''} • $_nights ليالٍ',
                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
              )),
              Text(_fmtMoney(_total, _currency), style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 14)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmation() {
    final ref = _result!['reference'] as String? ?? '';
    final status = _result!['status'] as String? ?? 'new';
    final total = _toDouble(_result!['estimatedTotal'], _total);
    final currency = (_result!['currency'] as String?) ?? _currency;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 24),
        Container(
          width: 88, height: 88, alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
          child: const Icon(Icons.check, color: Colors.white, size: 48),
        ),
        const SizedBox(height: 16),
        const Text('تم إرسال طلبك!', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        const Text('سيتواصل معك فريق الفندق قريبًا لتأكيد الحجز.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ملخص الطلب', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary, fontSize: 14)),
              const SizedBox(height: 12),
              _summaryRowItem(_SummaryRow('رقم المرجع', ref, emphasize: true)),
              _summaryRowItem(_SummaryRow('الحالة', statusLabelAr(status))),
              if (_roomType != null) _summaryRowItem(_SummaryRow('الغرفة', _roomType!.nameAr)),
              if (_checkIn != null) _summaryRowItem(_SummaryRow('الوصول', _fmtArDate(_checkIn!))),
              if (_checkOut != null) _summaryRowItem(_SummaryRow('المغادرة', _fmtArDate(_checkOut!))),
              _summaryRowItem(_SummaryRow('المدة', '$_nights ${_nights == 1 ? 'ليلة' : 'ليالٍ'}')),
              _summaryRowItem(_SummaryRow('الإجمالي التقديري', _fmtMoney(total, currency), emphasize: true)),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _waLaunching ? null : _openWhatsApp,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
            icon: _waLaunching
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.chat_outlined),
            label: Text(_waLaunching ? 'جارٍ التحضير...' : 'تواصل عبر واتساب'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/bookings', (route) => false),
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('متابعة الطلب'),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false),
          child: const Text('العودة للرئيسية'),
        ),
      ],
    );
  }

  Widget? _buildBottomBar() {
    if (_step == 2) return null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          if (_step == 1)
            OutlinedButton(
              onPressed: _submitting ? null : () => setState(() => _step = 0),
              child: const Text('رجوع'),
            ),
          if (_step == 1) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _submitting
                ? null
                : () {
                    if (_step == 0) {
                      setState(() => _step = 1);
                    } else if (_step == 1) {
                      _submit();
                    }
                  },
              icon: _submitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Icon(_step == 0 ? Icons.arrow_forward : Icons.send),
              label: Text(_submitting ? 'جارٍ الإرسال...' : (_step == 0 ? 'متابعة' : 'إرسال طلب الحجز')),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _summaryCard({required String title, required List<_SummaryRow> rows, _SummaryRow? total}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          ...rows.map((r) => _summaryRowItem(r)),
          if (total != null) ...[
            const Divider(height: 16),
            _summaryRowItem(total),
          ],
        ]),
      ),
    );
  }

  Widget _summaryRowItem(_SummaryRow r) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Expanded(child: Text(r.label, style: TextStyle(fontSize: 13, color: r.emphasize ? AppTheme.textPrimary : AppTheme.textSecondary, fontWeight: r.emphasize ? FontWeight.w700 : FontWeight.w400))),
      Text(r.value, style: TextStyle(fontSize: r.emphasize ? 16 : 13, color: r.emphasize ? AppTheme.primary : AppTheme.textPrimary, fontWeight: r.emphasize ? FontWeight.w800 : FontWeight.w500)),
    ]),
  );
}

class _SummaryRow {
  final String label;
  final String value;
  final bool emphasize;
  const _SummaryRow(this.label, this.value, {this.emphasize = false});
}

// ── Helpers ──
int _toInt(dynamic v, int def) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? def;
  return def;
}
double _toDouble(dynamic v, double def) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? def;
  return def;
}
DateTime? _parseDate(dynamic v) {
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}
String _fmtIso(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '$y-$m-$dd';
}
String _fmtArDate(DateTime d) {
  const months = ['يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}
String _fmtMoney(double amount, String currency) {
  final v = amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
  return currency == 'YER' ? '$v $kCurrencySymbol' : '$v $currency';
}

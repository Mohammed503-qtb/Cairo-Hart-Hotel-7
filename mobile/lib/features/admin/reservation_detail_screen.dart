import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../core/config.dart';
import '../../core/models.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';

/// Reservation detail — full Scaffold with AppBar + back button.
/// Shows full reservation info, payment list, state-machine action buttons,
/// record payment form, WhatsApp contact button, and audit trail.
class ReservationDetailScreen extends StatefulWidget {
  final String reservationId;
  const ReservationDetailScreen({super.key, required this.reservationId});

  @override
  State<ReservationDetailScreen> createState() => _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  AdminReservation? _r;
  List<Map<String, dynamic>> _payments = const [];
  List<AuditLog> _audit = const [];
  bool _loading = true;
  String? _error;
  bool _acting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = context.read<ApiClient>();
      final res = await api.get('/api/admin/reservations', query: {'pageSize': '500'}) as Map<String, dynamic>;
      final list = (res['items'] as List? ?? []).cast<Map<String, dynamic>>();
      final found = list.where((m) => m['id'] == widget.reservationId).toList();
      if (found.isEmpty) throw 'الحجز غير موجود';
      _r = AdminReservation.fromJson(found.first);
      final payRes = await api.get('/api/admin/payments', query: {'reservationId': widget.reservationId});
      _payments = (payRes is List ? payRes : const []).cast<Map<String, dynamic>>();
      final audRes = await api.get('/api/admin/audit', query: {'entity': 'reservation', 'limit': '50'});
      final audList = (audRes is List ? audRes : const []).cast<Map<String, dynamic>>();
      _audit = audList.where((m) => m['entityId'] == widget.reservationId).map(AuditLog.fromJson).toList();
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _doAction(String action, {String? reason}) async {
    if (_acting) return;
    setState(() => _acting = true);
    try {
      final api = context.read<ApiClient>();
      await api.post('/api/admin/reservations/${widget.reservationId}/action', body: {
        'action': action,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تنفيذ الإجراء'), backgroundColor: AppTheme.success));
      }
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل: ${e.toString()}'), backgroundColor: AppTheme.danger));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _confirmAction(String action, String label, {bool withReason = false}) async {
    String? reason;
    if (withReason) {
      reason = await _askReason(label);
      if (reason == null) return; // cancelled
    }
    await _doAction(action, reason: reason);
  }

  Future<String?> _askReason(String title) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'السبب (اختياري)', border: OutlineInputBorder()),
          maxLines: 2,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(c, ctrl.text.trim()), child: const Text('تنفيذ')),
        ],
      ),
    );
  }

  Future<void> _openPayment() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PaymentSheet(reservationId: widget.reservationId, remaining: _r?.remaining ?? 0, currency: _r?.currency ?? kDefaultCurrency),
    );
    if (result == true) _load();
  }

  Future<void> _openWhatsapp() async {
    if (_r == null) return;
    final phone = _normalizePhone(_r!.guestWhatsapp ?? _r!.guestPhone);
    if (phone == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يوجد رقم هاتف للضيف')));
      return;
    }
    final msg = Uri.encodeComponent(
      'مرحبًا ${_r!.guestName} 👋\n'
      'بخصوص حجزك رقم ${_r!.confirmationNo} في فندق قلب القاهرة:\n'
      'الغرفة: ${_r!.roomType}\n'
      'الوصول: ${_fmtDate(_r!.checkIn)}\n'
      'المغادرة: ${_fmtDate(_r!.checkOut)}\n'
      'الإجمالي: ${_fmtMoney(_r!.total, _r!.currency)}\n'
      'المتبقي: ${_fmtMoney(_r!.remaining, _r!.currency)}\n'
      'هل لديك أي استفسار؟',
    );
    final url = 'https://wa.me/$phone?text=$msg';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر فتح واتساب')));
    }
  }

  String? _normalizePhone(String? p) {
    if (p == null || p.trim().isEmpty) return null;
    var s = p.replaceAll(RegExp(r'[^0-9]'), '');
    if (s.startsWith('00')) s = s.substring(2);
    if (s.startsWith('967')) return s;
    if (s.length == 9 && s.startsWith('7')) return '967$s';
    if (s.length < 8) return null;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الحجز')),
      body: _loading
        ? const LoadingView(message: 'جارٍ تحميل الحجز')
        : _error != null
          ? ErrorView(message: 'تعذّر تحميل الحجز: $_error', onRetry: _load)
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  if (_r != null) ...[
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverToBoxAdapter(child: _buildGuestSection()),
                    SliverToBoxAdapter(child: _buildStaySection()),
                    SliverToBoxAdapter(child: _buildPriceSection()),
                    SliverToBoxAdapter(child: _buildPaymentsSection()),
                    SliverToBoxAdapter(child: _buildActionsSection()),
                    SliverToBoxAdapter(child: _buildAuditSection()),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final r = _r!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: AppTheme.primary,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(r.confirmationNo, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800))),
          StatusBadge(status: r.bookingStatus),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 6, children: [
          _chip('المصدر: ${r.source}'),
          if (r.createdBy != null) _chip('أنشأه: ${r.createdBy}'),
        ]),
      ]),
    );
  }

  Widget _chip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
  );

  Widget _buildSectionCard({required String title, required List<Widget> children, Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary))),
              ?trailing,
            ]),
            const SizedBox(height: 12),
            ...children,
          ]),
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w600))),
    ]),
  );

  Widget _buildGuestSection() => _buildSectionCard(
    title: 'بيانات الضيف',
    trailing: OutlinedButton.icon(
      onPressed: _openWhatsapp,
      icon: const Icon(Icons.chat_outlined, size: 16, color: Color(0xFF25D366)),
      label: const Text('واتساب', style: TextStyle(color: Color(0xFF25D366))),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        side: const BorderSide(color: Color(0xFF25D366)),
      ),
    ),
    children: [
      _row('الاسم', _r!.guestName),
      _row('الهاتف', _r!.guestPhone),
      if (_r!.guestWhatsapp != null && _r!.guestWhatsapp!.isNotEmpty) _row('واتساب', _r!.guestWhatsapp!),
    ],
  );

  Widget _buildStaySection() => _buildSectionCard(title: 'تفاصيل الإقامة', children: [
    _row('نوع الغرفة', _r!.roomType),
    if (_r!.roomNumber != null) _row('الغرفة', _r!.roomNumber!),
    _row('الوصول', _fmtDate(_r!.checkIn)),
    _row('المغادرة', _fmtDate(_r!.checkOut)),
    _row('عدد الليالي', '${_r!.nights}'),
    _row('البالغين', '${_r!.adults}'),
    _row('الأطفال', '${_r!.children}'),
    _row('تاريخ الإنشاء', _fmtDateTime(_r!.createdAt)),
  ]);

  Widget _buildPriceSection() => _buildSectionCard(title: 'التكلفة والمدفوعات', children: [
    _row('الإجمالي', _fmtMoney(_r!.total, _r!.currency)),
    _row('المدفوع', _fmtMoney(_r!.paid, _r!.currency)),
    _row('المتبقي', _fmtMoney(_r!.remaining, _r!.currency)),
    const SizedBox(height: 4),
    Row(children: [
      const Text('حالة الدفع: ', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      StatusBadge(status: _r!.paymentStatus, small: true),
    ]),
  ]);

  Widget _buildPaymentsSection() => _buildSectionCard(
    title: 'المدفوعات المسجّلة',
    trailing: OutlinedButton.icon(
      onPressed: _openPayment,
      icon: const Icon(Icons.add, size: 16),
      label: const Text('تسجيل دفعة'),
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
    ),
    children: [
      if (_payments.isEmpty)
        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('لا توجد مدفوعات مسجّلة بعد.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)))
      else
        for (final p in _payments) _PaymentRow(p: p, currency: _r!.currency),
    ],
  );

  Widget _buildActionsSection() {
    final status = _r!.bookingStatus;
    final actions = _allowedActions(status);
    if (actions.isEmpty) {
      return _buildSectionCard(title: 'الإجراءات', children: const [
        Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Row(children: [
          Icon(Icons.check_circle_outline, color: AppTheme.success, size: 18),
          SizedBox(width: 8),
          Expanded(child: Text('الحجز في حالة نهائية ولا يمكن اتخاذ إجراءات أخرى.', style: TextStyle(fontSize: 13, color: AppTheme.success, fontWeight: FontWeight.w600))),
        ])),
      ]);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('الإجراءات المتاحة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('الحالة الحالية: ${statusLabelAr(status)}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            if (_acting) const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
            else Wrap(spacing: 8, runSpacing: 8, children: actions.map((a) {
              return ElevatedButton.icon(
                onPressed: () => _confirmAction(a.action, a.label, withReason: a.withReason),
                icon: Icon(a.icon, size: 18),
                label: Text(a.label),
                style: ElevatedButton.styleFrom(
                  backgroundColor: a.color,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              );
            }).toList()),
          ]),
        ),
      ),
    );
  }

  Widget _buildAuditSection() {
    if (_audit.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      sliver: SliverToBoxAdapter(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('سجل التغييرات', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final log in _audit) _AuditRow(log: log),
            ]),
          ),
        ),
      ),
    );
  }

  List<_ActionDef> _allowedActions(String status) {
    switch (status) {
      case 'awaiting_confirmation':
        return [
          _ActionDef('confirm', 'تأكيد', Icons.check_circle, AppTheme.success),
          _ActionDef('reject', 'رفض', Icons.block, AppTheme.danger, withReason: true),
          _ActionDef('cancel', 'إلغاء', Icons.cancel_outlined, AppTheme.warning, withReason: true),
        ];
      case 'confirmed':
        return [
          _ActionDef('checkin', 'تسجيل دخول', Icons.login, AppTheme.success),
          _ActionDef('noshow', 'لم يحضر', Icons.person_off_outlined, AppTheme.warning, withReason: true),
          _ActionDef('cancel', 'إلغاء', Icons.cancel_outlined, AppTheme.danger, withReason: true),
        ];
      case 'checked_in':
        return [
          _ActionDef('checkout', 'تسجيل مغادرة', Icons.logout, AppTheme.info),
        ];
      case 'checked_out':
        return [
          _ActionDef('complete', 'إكمال', Icons.check, AppTheme.success),
        ];
      default:
        return const [];
    }
  }
}

class _ActionDef {
  final String action;
  final String label;
  final IconData icon;
  final Color color;
  final bool withReason;
  const _ActionDef(this.action, this.label, this.icon, this.color, {this.withReason = false});
}

class _PaymentRow extends StatelessWidget {
  final Map<String, dynamic> p;
  final String currency;
  const _PaymentRow({required this.p, required this.currency});

  @override
  Widget build(BuildContext context) {
    final amount = (p['amount'] as num?)?.toDouble() ?? 0;
    final method = (p['method'] as String?) ?? '';
    final status = (p['status'] as String?) ?? 'paid';
    final ref = (p['reference'] as String?) ?? '';
    final createdAt = p['createdAt'] as String?;
    final externalRef = p['externalRef'] as String?;
    final recordedBy = p['recordedBy'] as String?;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(ref, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
            Text(_fmtMoney(amount, currency), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.success)),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            _methodLabel(method),
            const SizedBox(width: 8),
            StatusBadge(status: status, small: true),
            const Spacer(),
            if (createdAt != null) Text(_fmtDateTime(DateTime.tryParse(createdAt) ?? DateTime.now()), style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ]),
          if (externalRef != null && externalRef.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('مرجع خارجي: $externalRef', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
          if (recordedBy != null) ...[
            const SizedBox(height: 2),
            Text('سجّلها: $recordedBy', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ]),
      ),
    );
  }

  Widget _methodLabel(String m) {
    const map = {'cash': 'نقدي', 'card': 'بطاقة', 'bank_transfer': 'تحويل بنكي', 'online': 'إلكتروني'};
    final label = map[m.toLowerCase()] ?? m;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppTheme.info.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.info, fontWeight: FontWeight.w700)),
    );
  }
}

class _AuditRow extends StatelessWidget {
  final AuditLog log;
  const _AuditRow({required this.log});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 4, height: 36, color: AppTheme.primary.withValues(alpha: 0.3)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${log.actor} · ${_actionLabel(log.action)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          if (log.oldValue != null && log.newValue != null)
            Text('${statusLabelAr(log.oldValue!)} ← ${statusLabelAr(log.newValue!)}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary))
          else if (log.newValue != null)
            Text(log.newValue!.length > 80 ? '${log.newValue!.substring(0, 80)}...' : log.newValue!, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          if (log.reason != null && log.reason!.isNotEmpty)
            Text('السبب: ${log.reason}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontStyle: FontStyle.italic)),
          Text(_fmtDateTime(log.createdAt), style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        ])),
      ]),
    );
  }
}

class _PaymentSheet extends StatefulWidget {
  final String reservationId;
  final double remaining;
  final String currency;
  const _PaymentSheet({required this.reservationId, required this.remaining, required this.currency});

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _externalRefCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _method = 'cash';
  String _status = 'paid';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.remaining > 0) _amountCtrl.text = widget.remaining.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountCtrl.dispose(); _externalRefCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final api = context.read<ApiClient>();
      await api.post('/api/admin/payments', body: {
        'reservationId': widget.reservationId,
        'method': _method,
        'amount': double.tryParse(_amountCtrl.text) ?? 0,
        if (_externalRefCtrl.text.trim().isNotEmpty) 'externalRef': _externalRefCtrl.text.trim(),
        if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
        'status': _status,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل الدفعة'), backgroundColor: AppTheme.success));
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
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: const BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 12), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(children: [
                  const Icon(Icons.payments_outlined, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text('تسجيل دفعة', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                ]),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: AppTheme.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        const Icon(Icons.info_outline, color: AppTheme.info, size: 16),
                        const SizedBox(width: 6),
                        Expanded(child: Text('المتبقي على الحجز: ${_fmtMoney(widget.remaining, widget.currency)}', style: const TextStyle(fontSize: 12, color: AppTheme.info, fontWeight: FontWeight.w600))),
                      ]),
                    ),
                    DropdownButtonFormField<String>(
                      value: _method,
                      decoration: const InputDecoration(labelText: 'طريقة الدفع', prefixIcon: Icon(Icons.payments_outlined)),
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('نقدي')),
                        DropdownMenuItem(value: 'card', child: Text('بطاقة')),
                        DropdownMenuItem(value: 'bank_transfer', child: Text('تحويل بنكي')),
                        DropdownMenuItem(value: 'online', child: Text('إلكتروني')),
                      ],
                      onChanged: (v) => setState(() => _method = v ?? 'cash'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _amountCtrl,
                      decoration: InputDecoration(labelText: 'المبلغ *', prefixIcon: const Icon(Icons.attach_money), suffixText: widget.currency),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'أدخل مبلغًا صحيحًا';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(labelText: 'الحالة', prefixIcon: Icon(Icons.flag_outlined)),
                      items: const [
                        DropdownMenuItem(value: 'paid', child: Text('مدفوع')),
                        DropdownMenuItem(value: 'pending', child: Text('بانتظار التأكيد')),
                      ],
                      onChanged: (v) => setState(() => _status = v ?? 'paid'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _externalRefCtrl,
                      decoration: const InputDecoration(labelText: 'المرجع الخارجي (اختياري)', prefixIcon: Icon(Icons.receipt_outlined)),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)', prefixIcon: Icon(Icons.note_outlined)),
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
                    child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('حفظ'),
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

String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

String _fmtDateTime(DateTime d) => '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String _fmtMoney(num amount, [String currency = kCurrencySymbol]) {
  final s = amount.toStringAsFixed(amount == amount.truncateToDouble() ? 0 : 2);
  return '$s $currency';
}

String _actionLabel(String a) {
  const map = <String, String>{
    'reservation.create': 'إنشاء',
    'reservation.confirm': 'تأكيد',
    'reservation.checkin': 'تسجيل دخول',
    'reservation.checkout': 'تسجيل مغادرة',
    'reservation.cancel': 'إلغاء',
    'reservation.noshow': 'لم يحضر',
    'reservation.complete': 'إكمال',
    'reservation.reject': 'رفض',
  };
  return map[a] ?? a;
}

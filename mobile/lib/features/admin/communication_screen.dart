import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';

/// Admin communication center — two tabs (Contact Requests + Booking Requests),
/// with status-filter and action buttons per request.
class CommunicationScreen extends StatefulWidget {
  const CommunicationScreen({super.key});
  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  String _status = '';

  final _statuses = const [
    ('', 'الكل'),
    ('new', 'جديد'),
    ('assigned', 'مُعيَّن'),
    ('contacted', 'تم التواصل'),
    ('waiting_customer', 'بانتظار العميل'),
    ('waiting_hotel', 'بانتظار الفندق'),
    ('confirmed', 'مؤكد'),
    ('converted', 'مُحوَّل'),
    ('closed', 'مغلق'),
    ('cancelled', 'ملغى'),
  ];

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _setStatus(String s) => setState(() => _status = s);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        Container(
          color: AppTheme.surface,
          child: TabBar(
            controller: _tab,
            tabs: const [
              Tab(text: 'طلبات التواصل', icon: Icon(Icons.mail_outline, size: 18)),
              Tab(text: 'طلبات الحجز', icon: Icon(Icons.receipt_long_outlined, size: 18)),
            ],
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            itemCount: _statuses.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, i) {
              final s = _statuses[i];
              final active = s.$1 == _status;
              return FilterChip(
                label: Text(s.$2),
                selected: active,
                onSelected: (_) => _setStatus(s.$1),
                selectedColor: s.$1.isEmpty ? AppTheme.primary : statusColor(s.$1),
                backgroundColor: AppTheme.background,
                labelStyle: TextStyle(color: active ? Colors.white : AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 11),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                visualDensity: VisualDensity.compact,
              );
            },
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _ContactRequestsTab(status: _status),
              _BookingRequestsTab(status: _status),
            ],
          ),
        ),
      ]),
    );
  }
}

class _ContactRequestsTab extends StatefulWidget {
  final String status;
  const _ContactRequestsTab({required this.status});
  @override
  State<_ContactRequestsTab> createState() => _ContactRequestsTabState();
}

class _ContactRequestsTabState extends State<_ContactRequestsTab> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_ContactRequestsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = context.read<ApiClient>();
      final res = await api.get('/api/admin/communication', query: widget.status.isEmpty ? null : {'status': widget.status}) as Map<String, dynamic>;
      final list = res['contactRequests'] as List? ?? const [];
      setState(() { _items = list.cast<Map<String, dynamic>>(); _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _doAction(Map<String, dynamic> item, String action, {String? label}) async {
    String? reason;
    if (action == 'cancel' || action == 'close') {
      reason = await _askReason(label ?? action);
      if (reason == null) return; // cancelled
    }
    try {
      final api = context.read<ApiClient>();
      await api.patch('/api/admin/communication', body: {
        'kind': 'contact',
        'id': item['id'],
        'action': action,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تنفيذ الإجراء'), backgroundColor: AppTheme.success));
      }
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل: ${e.toString()}'), backgroundColor: AppTheme.danger));
    }
  }

  Future<String?> _askReason(String title) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'السبب (اختياري)', border: OutlineInputBorder()), maxLines: 2, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(c, ctrl.text.trim()), child: const Text('تنفيذ')),
        ],
      ),
    );
  }

  Future<void> _openWhatsapp(String phone, String name, String? subject) async {
    final normalized = _normalizePhone(phone);
    if (normalized == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يوجد رقم هاتف صحيح')));
      return;
    }
    final msg = Uri.encodeComponent('مرحبًا $name 👋، بخصوص طلبك${subject != null && subject.isNotEmpty ? ' ($subject)' : ''} في فندق قلب القاهرة. كيف يمكننا مساعدتك؟');
    final uri = Uri.parse('https://wa.me/$normalized?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر فتح واتساب')));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: _load,
      child: _loading
        ? const LoadingView(message: 'جارٍ تحميل طلبات التواصل')
        : _error != null
          ? ErrorView(message: 'تعذّر تحميل الطلبات', onRetry: _load)
          : _items.isEmpty
            ? const EmptyView(message: 'لا توجد طلبات تواصل', icon: Icons.mail_outline)
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: _items.length,
                itemBuilder: (context, i) => _ContactCard(item: _items[i], onAction: _doAction, onWhatsapp: _openWhatsapp),
              ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final void Function(Map<String, dynamic>, String, {String? label}) onAction;
  final Future<void> Function(String, String, String?) onWhatsapp;
  const _ContactCard({required this.item, required this.onAction, required this.onWhatsapp});

  @override
  Widget build(BuildContext context) {
    final status = item['status']?.toString() ?? 'new';
    final priority = item['priority']?.toString() ?? 'normal';
    final guestName = item['guestName']?.toString() ?? '';
    final guestPhone = item['guestPhone']?.toString() ?? '';
    final channel = item['channel']?.toString() ?? 'app';
    final subject = item['subject'] as String?;
    final message = item['message'] as String?;
    final owner = item['owner'] as String?;
    final ref = item['reference']?.toString() ?? '';
    final createdAt = item['createdAt'] as String?;
    final priorityColor = _priorityColor(priority);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: priorityColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.flag, color: priorityColor, size: 14),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(ref, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800))),
            StatusBadge(status: status, small: true),
          ]),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 4, children: [
            _chip(Icons.person_outline, guestName),
            _chip(Icons.phone_outlined, guestPhone),
            _chip(Icons.swap_horiz, _channelLabel(channel)),
            if (owner != null) _chip(Icons.support_agent, 'المسؤول: $owner'),
          ]),
          if (subject != null && subject.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('الموضوع: $subject', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ],
          if (message != null && message.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(8)),
              child: Text(message, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
            ),
          ],
          if (createdAt != null) ...[
            const SizedBox(height: 4),
            Text('الإنشاء: ${_fmtDateTime(DateTime.tryParse(createdAt) ?? DateTime.now())}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
          const Divider(height: 14),
          Row(children: [
            Expanded(child: _buildActions(status)),
            const SizedBox(width: 6),
            OutlinedButton.icon(
              onPressed: () => onWhatsapp(guestPhone, guestName, subject),
              icon: const Icon(Icons.chat_outlined, size: 16, color: Color(0xFF25D366)),
              label: const Text('واتساب', style: TextStyle(color: Color(0xFF25D366), fontWeight: FontWeight.w700, fontSize: 12)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF25D366)), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), minimumSize: const Size(0, 32)),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _buildActions(String s) {
    final actions = <(String, String, IconData, Color)>[];
    if (s == 'new' || s == 'waiting_hotel') {
      actions.add(('assign', 'تعيين', Icons.assignment_ind_outlined, AppTheme.info));
      actions.add(('contact', 'تواصل', Icons.phone_in_talk_outlined, AppTheme.primary));
    }
    if (s == 'assigned' || s == 'contacted') {
      actions.add(('wait_customer', 'بانتظار العميل', Icons.hourglass_top_outlined, AppTheme.warning));
      actions.add(('wait_hotel', 'بانتظار الفندق', Icons.hourglass_bottom_outlined, AppTheme.warning));
      actions.add(('close', 'إغلاق', Icons.check, AppTheme.success));
    }
    if (s == 'waiting_customer') {
      actions.add(('contact', 'إعادة تواصل', Icons.phone_in_talk_outlined, AppTheme.primary));
      actions.add(('close', 'إغلاق', Icons.check, AppTheme.success));
    }
    if (s != 'closed' && s != 'cancelled') {
      actions.add(('cancel', 'إلغاء', Icons.cancel_outlined, AppTheme.danger));
    }
    return Wrap(spacing: 6, runSpacing: 6, children: actions.map((a) {
      return OutlinedButton.icon(
        onPressed: () => onAction(item, a.$1, label: a.$2),
        icon: Icon(a.$3, size: 16, color: a.$4),
        label: Text(a.$2, style: TextStyle(color: a.$4, fontWeight: FontWeight.w600, fontSize: 12)),
        style: OutlinedButton.styleFrom(side: BorderSide(color: a.$4.withValues(alpha: 0.5)), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), minimumSize: const Size(0, 32)),
      );
    }).toList());
  }

  Widget _chip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(6)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: AppTheme.textSecondary),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
    ]),
  );

  Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'high': case 'urgent': return AppTheme.danger;
      case 'normal': return AppTheme.primary;
      case 'low': return AppTheme.textSecondary;
      default: return AppTheme.textSecondary;
    }
  }
}

class _BookingRequestsTab extends StatefulWidget {
  final String status;
  const _BookingRequestsTab({required this.status});
  @override
  State<_BookingRequestsTab> createState() => _BookingRequestsTabState();
}

class _BookingRequestsTabState extends State<_BookingRequestsTab> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_BookingRequestsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = context.read<ApiClient>();
      final res = await api.get('/api/admin/communication', query: widget.status.isEmpty ? null : {'status': widget.status}) as Map<String, dynamic>;
      final list = res['bookingRequests'] as List? ?? const [];
      setState(() { _items = list.cast<Map<String, dynamic>>(); _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _doAction(Map<String, dynamic> item, String action, {String? label}) async {
    String? reason;
    if (action == 'cancel') {
      reason = await _askReason(label ?? action);
      if (reason == null) return;
    }
    try {
      final api = context.read<ApiClient>();
      await api.patch('/api/admin/communication', body: {
        'kind': 'booking',
        'id': item['id'],
        'action': action,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تنفيذ الإجراء'), backgroundColor: AppTheme.success));
      }
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل: ${e.toString()}'), backgroundColor: AppTheme.danger));
    }
  }

  Future<String?> _askReason(String title) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'السبب (اختياري)', border: OutlineInputBorder()), maxLines: 2, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(c, ctrl.text.trim()), child: const Text('تنفيذ')),
        ],
      ),
    );
  }

  Future<void> _openWhatsapp(String phone, String name) async {
    final normalized = _normalizePhone(phone);
    if (normalized == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يوجد رقم هاتف صحيح')));
      return;
    }
    final msg = Uri.encodeComponent('مرحبًا $name 👋، بخصوص طلب الحجز في فندق قلب القاهرة. كيف يمكننا مساعدتك؟');
    final uri = Uri.parse('https://wa.me/$normalized?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر فتح واتساب')));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: _load,
      child: _loading
        ? const LoadingView(message: 'جارٍ تحميل طلبات الحجز')
        : _error != null
          ? ErrorView(message: 'تعذّر تحميل الطلبات', onRetry: _load)
          : _items.isEmpty
            ? const EmptyView(message: 'لا توجد طلبات حجز', icon: Icons.receipt_long_outlined)
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: _items.length,
                itemBuilder: (context, i) => _BookingCard(item: _items[i], onAction: _doAction, onWhatsapp: _openWhatsapp),
              ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final void Function(Map<String, dynamic>, String, {String? label}) onAction;
  final Future<void> Function(String, String) onWhatsapp;
  const _BookingCard({required this.item, required this.onAction, required this.onWhatsapp});

  @override
  Widget build(BuildContext context) {
    final status = item['status']?.toString() ?? 'new';
    final priority = item['priority']?.toString() ?? 'normal';
    final guestName = item['guestName']?.toString() ?? '';
    final guestPhone = item['guestPhone']?.toString() ?? '';
    final guestWhatsapp = item['guestWhatsapp'] as String?;
    final channel = item['channel']?.toString() ?? 'app';
    final message = item['message'] as String?;
    final owner = item['owner'] as String?;
    final ref = item['reference']?.toString() ?? '';
    final createdAt = item['createdAt'] as String?;
    final checkIn = item['checkIn'] as String?;
    final checkOut = item['checkOut'] as String?;
    final nights = item['nights']?.toString();
    final adults = item['adults']?.toString();
    final children = item['children']?.toString();
    final roomType = item['roomType'] as Map<String, dynamic>?;
    final reservationNo = item['reservationNo'] as String?;
    final priorityColor = _priorityColor(priority);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: priorityColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.flag, color: priorityColor, size: 14),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(ref, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800))),
            StatusBadge(status: status, small: true),
          ]),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 4, children: [
            _chip(Icons.person_outline, guestName),
            _chip(Icons.phone_outlined, guestPhone),
            _chip(Icons.swap_horiz, _channelLabel(channel)),
            if (roomType != null) _chip(Icons.bed_outlined, roomType['nameAr']?.toString() ?? ''),
            if (owner != null) _chip(Icons.support_agent, 'المسؤول: $owner'),
            if (reservationNo != null) _chip(Icons.book_online, 'حجز: $reservationNo'),
          ]),
          if (checkIn != null && checkOut != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text('${_fmtDate(DateTime.tryParse(checkIn) ?? DateTime.now())} → ${_fmtDate(DateTime.tryParse(checkOut) ?? DateTime.now())}${nights != null ? ' · $nights ليالٍ' : ''}${adults != null ? ' · $adults بالغ' : ''}${children != null && children != '0' ? ' · $children طفل' : ''}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ]),
          ],
          if (message != null && message.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(8)),
              child: Text(message, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
            ),
          ],
          if (createdAt != null) ...[
            const SizedBox(height: 4),
            Text('الإنشاء: ${_fmtDateTime(DateTime.tryParse(createdAt) ?? DateTime.now())}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
          const Divider(height: 14),
          Row(children: [
            Expanded(child: _buildActions(status)),
            const SizedBox(width: 6),
            OutlinedButton.icon(
              onPressed: () => onWhatsapp(guestWhatsapp ?? guestPhone, guestName),
              icon: const Icon(Icons.chat_outlined, size: 16, color: Color(0xFF25D366)),
              label: const Text('واتساب', style: TextStyle(color: Color(0xFF25D366), fontWeight: FontWeight.w700, fontSize: 12)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF25D366)), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), minimumSize: const Size(0, 32)),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _buildActions(String s) {
    final actions = <(String, String, IconData, Color)>[];
    if (s == 'new' || s == 'waiting_hotel') {
      actions.add(('assign', 'تعيين', Icons.assignment_ind_outlined, AppTheme.info));
      actions.add(('contact', 'تواصل', Icons.phone_in_talk_outlined, AppTheme.primary));
    }
    if (s == 'assigned' || s == 'contacted' || s == 'waiting_customer') {
      actions.add(('confirm', 'تأكيد', Icons.check_circle_outline, AppTheme.success));
      actions.add(('convert', 'تحويل لحجز', Icons.swap_horiz, AppTheme.primary));
      actions.add(('close', 'إغلاق', Icons.check, AppTheme.success));
    }
    if (s == 'confirmed') {
      actions.add(('convert', 'تحويل لحجز', Icons.swap_horiz, AppTheme.primary));
    }
    if (s != 'converted' && s != 'closed' && s != 'cancelled') {
      actions.add(('cancel', 'إلغاء', Icons.cancel_outlined, AppTheme.danger));
    }
    return Wrap(spacing: 6, runSpacing: 6, children: actions.map((a) {
      return OutlinedButton.icon(
        onPressed: () => onAction(item, a.$1, label: a.$2),
        icon: Icon(a.$3, size: 16, color: a.$4),
        label: Text(a.$2, style: TextStyle(color: a.$4, fontWeight: FontWeight.w600, fontSize: 12)),
        style: OutlinedButton.styleFrom(side: BorderSide(color: a.$4.withValues(alpha: 0.5)), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), minimumSize: const Size(0, 32)),
      );
    }).toList());
  }

  Widget _chip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(6)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: AppTheme.textSecondary),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
    ]),
  );

  Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'high': case 'urgent': return AppTheme.danger;
      case 'normal': return AppTheme.primary;
      case 'low': return AppTheme.textSecondary;
      default: return AppTheme.textSecondary;
    }
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

String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

String _fmtDateTime(DateTime d) => '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';

String _channelLabel(String c) => const {'app': 'تطبيق', 'whatsapp': 'واتساب', 'phone': 'هاتف', 'web': 'موقع'}[c.toLowerCase()] ?? c;

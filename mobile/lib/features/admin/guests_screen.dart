import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';

/// Admin guests — searchable list with details sheet.
class AdminGuestsScreen extends StatefulWidget {
  const AdminGuestsScreen({super.key});
  @override
  State<AdminGuestsScreen> createState() => _AdminGuestsScreenState();
}

class _AdminGuestsScreenState extends State<AdminGuestsScreen> {
  List<Map<String, dynamic>> _items = const [];
  int _total = 0;
  bool _loading = true;
  String? _error;
  String _q = '';
  final _searchCtrl = TextEditingController();

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
      final res = await api.get('/api/admin/guests', query: _q.isEmpty ? null : {'q': _q}) as Map<String, dynamic>;
      final list = res['guests'] as List? ?? const [];
      setState(() {
        _items = list.cast<Map<String, dynamic>>();
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

  Future<void> _openDetails(Map<String, dynamic> guest) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => _GuestDetailSheet(guest: guest),
    );
  }

  Future<void> _openWhatsapp(String? phone, String name) async {
    final normalized = _normalizePhone(phone);
    if (normalized == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يوجد رقم واتساب')));
      return;
    }
    final msg = Uri.encodeComponent('مرحبًا $name 👋، مع فندق قلب القاهرة. كيف يمكننا مساعدتك؟');
    final uri = Uri.parse('https://wa.me/$normalized?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر فتح واتساب')));
    }
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'ابحث بالاسم أو رقم الهاتف',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    suffixIcon: IconButton(icon: const Icon(Icons.send, size: 18), onPressed: _applySearch),
                  ),
                  onSubmitted: (_) => _applySearch(),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('الإجمالي: $_total ضيف', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(child: LoadingView(message: 'جارٍ تحميل الضيوف'))
            else if (_error != null)
              SliverFillRemaining(child: ErrorView(message: 'تعذّر تحميل الضيوف', onRetry: _load))
            else if (_items.isEmpty)
              SliverFillRemaining(child: EmptyView(message: _q.isEmpty ? 'لا يوجد ضيوف بعد' : 'لا نتائج مطابقة', icon: Icons.people_outline))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                sliver: SliverList.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, i) => _GuestCard(
                    guest: _items[i],
                    onTap: () => _openDetails(_items[i]),
                    onWhatsapp: () => _openWhatsapp(_items[i]['whatsapp']?.toString() ?? _items[i]['phone']?.toString(), _items[i]['name']?.toString() ?? ''),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GuestCard extends StatelessWidget {
  final Map<String, dynamic> guest;
  final VoidCallback onTap;
  final VoidCallback onWhatsapp;
  const _GuestCard({required this.guest, required this.onTap, required this.onWhatsapp});

  @override
  Widget build(BuildContext context) {
    final name = guest['name']?.toString() ?? '';
    final phone = guest['phone']?.toString() ?? '';
    final email = guest['email'] as String?;
    final reservations = guest['reservationsCount']?.toString() ?? '0';
    final requests = guest['requestsCount']?.toString() ?? '0';
    final blacklisted = guest['blacklisted'] == true;
    final createdAt = guest['createdAt'] as String?;
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: (blacklisted ? AppTheme.danger : AppTheme.primary).withValues(alpha: 0.15),
              child: Text(initials, style: TextStyle(color: blacklisted ? AppTheme.danger : AppTheme.primary, fontSize: 16, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (blacklisted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                    child: const Text('قائمة سوداء', style: TextStyle(fontSize: 9, color: AppTheme.danger, fontWeight: FontWeight.w800)),
                  ),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.phone_outlined, size: 12, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(phone, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ]),
              if (email != null && email.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.mail_outline, size: 12, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(child: Text(email, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
              ],
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 4, children: [
                _miniChip(Icons.book_online, '$reservations حجز', AppTheme.info),
                _miniChip(Icons.receipt_long, '$requests طلب', AppTheme.warning),
              ]),
              if (createdAt != null) ...[
                const SizedBox(height: 4),
                Text('منذ: ${_fmtDate(DateTime.tryParse(createdAt) ?? DateTime.now())}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ])),
            IconButton(icon: const Icon(Icons.chat_outlined, color: Color(0xFF25D366), size: 20), onPressed: onWhatsapp, tooltip: 'واتساب'),
          ]),
        ),
      ),
    );
  }

  Widget _miniChip(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 10, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
    ]),
  );
}

class _GuestDetailSheet extends StatelessWidget {
  final Map<String, dynamic> guest;
  const _GuestDetailSheet({required this.guest});

  @override
  Widget build(BuildContext context) {
    final name = guest['name']?.toString() ?? '';
    final phone = guest['phone']?.toString() ?? '';
    final whatsapp = guest['whatsapp'] as String?;
    final email = guest['email'] as String?;
    final notes = guest['notes'] as String?;
    final blacklisted = guest['blacklisted'] == true;
    final reservations = guest['reservationsCount']?.toString() ?? '0';
    final requests = guest['requestsCount']?.toString() ?? '0';
    final createdAt = guest['createdAt'] as String?;
    final guestId = guest['id']?.toString() ?? '';

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      decoration: const BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 12), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: (blacklisted ? AppTheme.danger : AppTheme.primary).withValues(alpha: 0.15),
                  child: Text(name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?', style: TextStyle(color: blacklisted ? AppTheme.danger : AppTheme.primary, fontSize: 22, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  if (blacklisted)
                    const Text('ضيف في القائمة السوداء', style: TextStyle(fontSize: 11, color: AppTheme.danger, fontWeight: FontWeight.w700)),
                ])),
              ]),
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _statTile(Icons.book_online, reservations, 'حجوزات', AppTheme.info),
                _statTile(Icons.receipt_long, requests, 'طلبات', AppTheme.warning),
              ]),
              const SizedBox(height: 16),
              _infoRow('الرقم', '#$guestId'),
              _infoRow('الهاتف', phone),
              if (whatsapp != null && whatsapp.isNotEmpty) _infoRow('واتساب', whatsapp),
              if (email != null && email.isNotEmpty) _infoRow('البريد', email),
              if (notes != null && notes.isNotEmpty) _infoRow('ملاحظات', notes),
              if (createdAt != null) _infoRow('منذ', _fmtDate(DateTime.tryParse(createdAt) ?? DateTime.now())),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final normalized = _normalizePhone(whatsapp ?? phone);
                    if (normalized == null) return;
                    final msg = Uri.encodeComponent('مرحبًا $name 👋، مع فندق قلب القاهرة. كيف يمكننا مساعدتك؟');
                    final uri = Uri.parse('https://wa.me/$normalized?text=$msg');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('تواصل عبر واتساب'),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _statTile(IconData icon, String value, String label, Color color) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
      ]),
    ]),
  );

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w600))),
    ]),
  );
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

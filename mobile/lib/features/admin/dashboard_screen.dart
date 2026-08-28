import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/config.dart';
import '../../core/models.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';
import 'admin_shell.dart';

/// Dashboard — overview stats, "Needs Attention" list, recent activity timeline.
/// Hosted inside AdminShell's body. Tapping stat cards switches the shell's tab.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardData? _data;
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
      final json = await api.get('/api/admin/dashboard') as Map<String, dynamic>;
      setState(() { _data = DashboardData.fromJson(json); _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _navigateToSection(String link) {
    const map = <String, int>{
      '/admin/reservations': 1,
      '/admin/rooms': 2,
      '/admin/room-types': 3,
      '/admin/services': 4,
      '/admin/offers': 5,
      '/admin/service-requests': 6,
      '/admin/communication': 7,
      '/admin/content': 8,
      '/admin/guests': 9,
      '/admin/users': 10,
      '/admin/audit': 11,
      '/admin/settings': 12,
    };
    final idx = map[link];
    if (idx != null) {
      context.findAncestorStateOfType<AdminShellState>()?.navigateTo(idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
          ? const LoadingView(message: 'جارٍ تحميل اللوحة')
          : _error != null
            ? ErrorView(message: 'تعذّر تحميل اللوحة: $_error', onRetry: _load)
            : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: _buildGreeting(),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    sliver: SliverToBoxAdapter(child: _buildAttention()),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.05,
                      ),
                      delegate: SliverChildListDelegate(_buildStatCards()),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    sliver: SliverToBoxAdapter(child: _buildRevenue()),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    sliver: SliverToBoxAdapter(child: SectionTitle(title: 'النشاط الأخير', subtitle: 'آخر العمليات على النظام')),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    sliver: SliverList.builder(
                      itemCount: _data?.recentActivity.length ?? 0,
                      itemBuilder: (context, i) => _ActivityTile(log: _data!.recentActivity[i]),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildGreeting() {
    final userName = _data?.user['name']?.toString() ?? 'مستخدم';
    final roles = _data?.user['roleNames'];
    final roleLabel = (roles is List && roles.isNotEmpty) ? roles.first.toString() : 'موظف';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.person, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('مرحبًا، $userName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(roleLabel, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ])),
          IconButton(
            icon: const Icon(Icons.history, color: AppTheme.textSecondary),
            tooltip: 'سجل التدقيق',
            onPressed: () => _navigateToSection('/admin/audit'),
          ),
        ]),
      ),
    );
  }

  Widget _buildAttention() {
    final attention = _data?.attention ?? const [];
    if (attention.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            const Icon(Icons.check_circle_outline, color: AppTheme.success, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text('لا توجد عناصر بانتظار اهتمامك الآن. كل شيء تحت السيطرة.', style: const TextStyle(fontSize: 13, color: AppTheme.success, fontWeight: FontWeight.w600))),
          ]),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Row(children: [
              const Icon(Icons.notifications_active, color: AppTheme.warning, size: 18),
              const SizedBox(width: 8),
              const Text('بانتظار اهتمامك', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            ]),
          ),
          for (final a in attention) _AttentionTile(
            label: (a['labelAr'] ?? a['labelEn'] ?? '').toString(),
            count: (a['count'] as num?)?.toInt() ?? 0,
            link: (a['link'] ?? '').toString(),
            onTap: () => _navigateToSection((a['link'] ?? '').toString()),
          ),
        ]),
      ),
    );
  }

  List<Widget> _buildStatCards() {
    final s = _data?.stats ?? const {};
    int val(String k) => (s[k] as num?)?.toInt() ?? 0;
    return [
      statCard(label: 'وصولات اليوم', value: '${val('todaysCheckins')}', icon: Icons.login, color: AppTheme.info, onTap: () => _navigateToSection('/admin/reservations')),
      statCard(label: 'مغادرات اليوم', value: '${val('todaysCheckouts')}', icon: Icons.logout, color: AppTheme.warning, onTap: () => _navigateToSection('/admin/reservations')),
      statCard(label: 'غرف مشغولة', value: '${val('occupiedRooms')}', icon: Icons.bed, color: AppTheme.success, onTap: () => _navigateToSection('/admin/rooms')),
      statCard(label: 'غرف متاحة', value: '${val('availableRooms')}', icon: Icons.bed_outlined, color: AppTheme.info, onTap: () => _navigateToSection('/admin/rooms')),
      statCard(label: 'تحت التنظيف', value: '${val('cleaningRooms')}', icon: Icons.cleaning_services_outlined, color: AppTheme.warning, onTap: () => _navigateToSection('/admin/rooms')),
      statCard(label: 'تحت الصيانة', value: '${val('maintenanceRooms')}', icon: Icons.build, color: AppTheme.danger, onTap: () => _navigateToSection('/admin/rooms')),
      statCard(label: 'مدفوعات معلّقة', value: '${val('pendingPayments')}', icon: Icons.payments_outlined, color: AppTheme.warning, onTap: () => _navigateToSection('/admin/reservations')),
      statCard(label: 'طلبات حجز جديدة', value: '${val('newBookingRequests')}', icon: Icons.receipt_long, color: AppTheme.primary, onTap: () => _navigateToSection('/admin/communication')),
      statCard(label: 'طلبات تواصل', value: '${val('newContactRequests')}', icon: Icons.chat, color: AppTheme.info, onTap: () => _navigateToSection('/admin/communication')),
      statCard(label: 'طلبات خدمات', value: '${val('openServiceRequests')}', icon: Icons.room_service, color: AppTheme.danger, onTap: () => _navigateToSection('/admin/service-requests')),
      statCard(label: 'إجمالي الضيوف', value: '${val('totalGuests')}', icon: Icons.people_outline, color: AppTheme.accent, onTap: () => _navigateToSection('/admin/guests')),
      statCard(label: 'إجمالي الحجوزات', value: '${val('totalReservations')}', icon: Icons.book_online, color: AppTheme.primary, onTap: () => _navigateToSection('/admin/reservations')),
    ];
  }

  Widget _buildRevenue() {
    final s = _data?.stats ?? const {};
    final revenue = (s['revenueToday'] as num?)?.toDouble() ?? 0;
    return Card(
      color: AppTheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.attach_money, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('إيرادات اليوم', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 2),
            Text(_fmtMoney(revenue), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          ])),
        ]),
      ),
    );
  }
}

class _AttentionTile extends StatelessWidget {
  final String label;
  final int count;
  final String link;
  final VoidCallback onTap;
  const _AttentionTile({required this.label, required this.count, required this.link, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: Text('$count', style: const TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w800, fontSize: 13)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary))),
          const Icon(Icons.chevron_left, color: AppTheme.textSecondary, size: 18),
        ]),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final AuditLog log;
  const _ActivityTile({required this.log});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.history, size: 18, color: AppTheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(log.actor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
              Text(_fmtTime(log.createdAt), style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ]),
            const SizedBox(height: 2),
            Text('${_actionLabel(log.action)} · ${_entityLabel(log.entity)}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            if (log.reason != null && log.reason!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text('السبب: ${log.reason}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontStyle: FontStyle.italic)),
            ],
          ])),
        ]),
      ),
    );
  }
}

String _fmtMoney(num amount) {
  final s = amount.toStringAsFixed(amount == amount.truncateToDouble() ? 0 : 2);
  return '$s $kCurrencySymbol';
}

String _fmtTime(DateTime d) {
  final now = DateTime.now();
  final diff = now.difference(d);
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) return 'قبل ${diff.inMinutes} دقيقة';
  if (diff.inHours < 24) return 'قبل ${diff.inHours} ساعة';
  if (diff.inDays < 7) return 'قبل ${diff.inDays} يوم';
  return '${d.day}/${d.month}/${d.year}';
}

String _actionLabel(String a) {
  const map = <String, String>{
    'reservation.create': 'إنشاء حجز',
    'reservation.confirm': 'تأكيد حجز',
    'reservation.checkin': 'تسجيل دخول',
    'reservation.checkout': 'تسجيل مغادرة',
    'reservation.cancel': 'إلغاء حجز',
    'reservation.noshow': 'لم يحضر',
    'reservation.complete': 'إكمال',
    'reservation.reject': 'رفض',
    'room.status_change': 'تغيير حالة غرفة',
    'payment.record': 'تسجيل دفعة',
    'service_request.accept': 'قبول طلب خدمة',
    'service_request.assign': 'تعيين طلب خدمة',
    'service_request.complete': 'إكمال طلب خدمة',
    'settings.update': 'تحديث الإعدادات',
    'feature_flag.update': 'تحديث ميزة',
    'room_type.create': 'إنشاء نوع غرفة',
    'room_type.edit': 'تعديل نوع غرفة',
    'service.create': 'إنشاء خدمة',
    'service.edit': 'تعديل خدمة',
    'offer.create': 'إنشاء عرض',
    'offer.edit': 'تعديل عرض',
    'content.edit': 'تعديل محتوى',
    'contact_request.assign': 'تعيين تواصل',
    'contact_request.contact': 'تواصل مع عميل',
    'contact_request.close': 'إغلاق تواصل',
    'booking_request.convert': 'تحويل طلب لحجز',
    'booking_request.confirm': 'تأكيد طلب',
  };
  return map[a] ?? a;
}

String _entityLabel(String e) {
  const map = <String, String>{
    'reservation': 'حجز',
    'room': 'غرفة',
    'payment': 'دفعة',
    'service_request': 'طلب خدمة',
    'room_type': 'نوع غرفة',
    'service': 'خدمة',
    'offer': 'عرض',
    'content_section': 'قسم محتوى',
    'hotel_settings': 'إعدادات الفندق',
    'feature_flag': 'ميزة',
    'contact_request': 'طلب تواصل',
    'booking_request': 'طلب حجز',
    'guest': 'ضيف',
  };
  return map[e] ?? e;
}

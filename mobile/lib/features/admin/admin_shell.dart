import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/storage/app_store.dart';
import '../../core/network/api_client.dart';
import 'dashboard_screen.dart';
import 'reservations_screen.dart';
import 'rooms_screen.dart';
import 'room_types_screen.dart';
import 'services_screen.dart';
import 'offers_screen.dart';
import 'content_screen.dart';
import 'service_requests_screen.dart';
import 'communication_screen.dart';
import 'settings_screen.dart';
import 'audit_screen.dart';
import 'users_screen.dart';
import 'guests_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => AdminShellState();
}

class AdminShellState extends State<AdminShell> {
  int _index = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _items = <_NavItem>[
    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'لوحة المعلومات', route: '/admin/dashboard'),
    _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'الحجوزات', route: '/admin/reservations'),
    _NavItem(icon: Icons.bed_outlined, activeIcon: Icons.bed, label: 'الغرف', route: '/admin/rooms'),
    _NavItem(icon: Icons.category_outlined, activeIcon: Icons.category, label: 'أنواع الغرف', route: '/admin/room-types'),
    _NavItem(icon: Icons.room_service_outlined, activeIcon: Icons.room_service, label: 'الخدمات', route: '/admin/services'),
    _NavItem(icon: Icons.local_offer_outlined, activeIcon: Icons.local_offer, label: 'العروض', route: '/admin/offers'),
    _NavItem(icon: Icons.build_outlined, activeIcon: Icons.build, label: 'طلبات الخدمات', route: '/admin/service-requests'),
    _NavItem(icon: Icons.chat_outlined, activeIcon: Icons.chat, label: 'التواصل', route: '/admin/communication'),
    _NavItem(icon: Icons.article_outlined, activeIcon: Icons.article, label: 'المحتوى', route: '/admin/content'),
    _NavItem(icon: Icons.people_outlined, activeIcon: Icons.people, label: 'الضيوف', route: '/admin/guests'),
    _NavItem(icon: Icons.manage_accounts_outlined, activeIcon: Icons.manage_accounts, label: 'المستخدمون', route: '/admin/users'),
    _NavItem(icon: Icons.history_outlined, activeIcon: Icons.history, label: 'سجل التدقيق', route: '/admin/audit'),
    _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'الإعدادات', route: '/admin/settings'),
  ];

  final _screens = <Widget>[];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      const DashboardScreen(),
      const ReservationsScreen(),
      const AdminRoomsScreen(),
      const AdminRoomTypesScreen(),
      const AdminServicesScreen(),
      const AdminOffersScreen(),
      const AdminServiceRequestsScreen(),
      const CommunicationScreen(),
      const ContentScreen(),
      const AdminGuestsScreen(),
      const AdminUsersScreen(),
      const AuditScreen(),
      const AdminSettingsScreen(),
    ]);
  }

  void navigateTo(int i) => setState(() => _index = i);

  Future<bool> _confirmSignOut() async {
    return (await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('تسجيل الخروج'),
      content: const Text('هل تريد العودة إلى واجهة الضيف؟'),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('نعم'))],
    ))) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    final store = context.read<AppStore>();
    final api = context.read<ApiClient>();
    final item = _items[_index];

    Widget body = Row(children: [
      if (isWide) _buildRail(),
      Expanded(child: Scaffold(
        appBar: AppBar(
          leading: isWide ? null : IconButton(icon: const Icon(Icons.menu), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
          title: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w700)),
          actions: [
            IconButton(icon: const Icon(Icons.home_outlined), tooltip: 'العودة للضيف', onPressed: () async {
              if (await _confirmSignOut()) {
                store.exitToGuest();
                await api.clearToken();
                Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
              }
            }),
            const SizedBox(width: 8),
          ],
        ),
        body: _screens[_index],
      )),
    ]);

    if (isWide) return body;
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
        title: Text(item.label),
        actions: [
          IconButton(icon: const Icon(Icons.home_outlined), tooltip: 'العودة للضيف', onPressed: () async {
            if (await _confirmSignOut()) {
              store.exitToGuest();
              await api.clearToken();
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
            }
          }),
        ],
      ),
      drawer: Drawer(child: _buildDrawer()),
      body: _screens[_index],
    );
  }

  Widget _buildRail() => Container(
    width: 260, color: AppTheme.accent,
    child: SafeArea(child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 16), child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.hotel, color: Colors.white, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('قلب القاهرة', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
          Text('لوحة الإدارة', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
        ])),
      ])),
      const Divider(color: Colors.white24, height: 1),
      Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(vertical: 8), itemCount: _items.length, itemBuilder: (_, i) {
        final it = _items[i];
        final active = i == _index;
        return Material(color: Colors.transparent, child: InkWell(onTap: () => navigateTo(i), child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: active ? AppTheme.primary.withValues(alpha: 0.18) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Icon(active ? it.activeIcon : it.icon, color: active ? AppTheme.primary : Colors.white70, size: 20),
            const SizedBox(width: 12),
            Text(it.label, style: TextStyle(color: active ? AppTheme.primary : Colors.white70, fontSize: 14, fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
          ]),
        )));
      })),
    ])),
  );

  Widget _buildDrawer() => Container(
    color: AppTheme.accent, width: 280,
    child: SafeArea(child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 16), child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.hotel, color: Colors.white, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('قلب القاهرة', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
          Text('لوحة الإدارة', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
        ])),
      ])),
      const Divider(color: Colors.white24, height: 1),
      Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(vertical: 8), itemCount: _items.length, itemBuilder: (ctx, i) {
        final it = _items[i];
        final active = i == _index;
        return Material(color: Colors.transparent, child: InkWell(onTap: () { Navigator.pop(ctx); navigateTo(i); }, child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: active ? AppTheme.primary.withValues(alpha: 0.18) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Icon(active ? it.activeIcon : it.icon, color: active ? AppTheme.primary : Colors.white70, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(it.label, style: TextStyle(color: active ? AppTheme.primary : Colors.white70, fontSize: 14, fontWeight: active ? FontWeight.w700 : FontWeight.w500))),
          ]),
        )));
      })),
    ])),
  );
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.route});
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hotel_platform/core/app_state.dart';
import 'package:hotel_platform/core/constants.dart';
import 'package:hotel_platform/core/utils/format.dart';
import 'package:hotel_platform/core/utils/responsive.dart';
import 'package:hotel_platform/data/models.dart';
import 'package:hotel_platform/data/store.dart';
import 'package:hotel_platform/features/admin/staff_codes_screen.dart';
import 'package:hotel_platform/l10n/app_localizations.dart';
import 'package:hotel_platform/shared/widgets/common_widgets.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static final _pages = [
    _AdminDashboard(),
    _RoomTypesPage(),
    _ServicesPage(),
    _StaffCodesLinkPage(),
    _UsersPage(),
    _AuditPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final app = context.watch<AppState>();
    final isWide = context.isDesktop;
    final tabs = [
      _Tab(l.dashboard, Icons.dashboard_outlined),
      _Tab(l.roomTypes, Icons.bed_outlined),
      _Tab(l.servicesCatalog, Icons.room_service_outlined),
      _Tab(l.staffCodes, Icons.vpn_key_outlined),
      _Tab(l.users, Icons.people_outline),
      _Tab(l.auditLog, Icons.history),
    ];
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(
              Icons.admin_panel_settings,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(l.appName, style: const TextStyle(fontSize: 17)),
            const SizedBox(width: 10),
            const Text('·', style: TextStyle(color: Colors.grey)),
            const SizedBox(width: 10),
            Text(l.admin, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.translate),
            onPressed: () => app.toggleLocale(),
            tooltip: l.switchLang,
          ),
          IconButton(
            icon: Icon(
              app.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            onPressed: () => app.setThemeMode(
              app.isDark ? AppThemeMode.light : AppThemeMode.dark,
            ),
            tooltip: l.switchTheme,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              app.signOut();
              context.go('/login');
            },
            tooltip: l.logout,
          ),
        ],
      ),
      body: isWide
          ? Row(
              children: [
                NavigationRail(
                  extended: true,
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  destinations: tabs
                      .map(
                        (t) => NavigationRailDestination(
                          icon: Icon(t.icon),
                          label: Text(t.label),
                        ),
                      )
                      .toList(),
                ),
                Expanded(
                  child: IndexedStack(index: _index, children: _pages),
                ),
              ],
            )
          : IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: tabs
                  .map(
                    (t) => NavigationDestination(
                      icon: Icon(t.icon),
                      label: t.label,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _Tab {
  final String label;
  final IconData icon;
  const _Tab(this.label, this.icon);
}

class _StaffCodesLinkPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final store = context.watch<HotelStore>();
    final theme = Theme.of(context);
    final codes = store.staffAccesses;
    final active = codes.where((c) => c.active).length;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.vpn_key_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.staffCodes,
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l.staffCodesSub,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                KpiCard(
                  label: l.active,
                  value: '$active',
                  icon: Icons.vpn_key,
                  color: const Color(0xFF2E7D32),
                ),
                const SizedBox(width: 14),
                KpiCard(
                  label: l.inactive,
                  value: '${codes.length - active}',
                  icon: Icons.block,
                  color: const Color(0xFF9E9E9E),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: () => context.push('/admin/staff-codes'),
                icon: const Icon(Icons.settings),
                label: Text(l.createStaffCode),
              ),
            ),
            const SizedBox(height: 18),
            ...codes.take(5).map((sa) {
              final roleColor = sa.role == 'admin'
                  ? const Color(0xFF6A1B9A)
                  : const Color(0xFFEF6C00);
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: roleColor.withOpacity(0.14),
                    child: Icon(
                      sa.role == 'admin'
                          ? Icons.admin_panel_settings
                          : Icons.support_agent,
                      color: roleColor,
                    ),
                  ),
                  title: Text(sa.staffName),
                  subtitle: Text(
                    '${sa.code} • ${sa.role == 'admin' ? l.admin : l.reception}',
                  ),
                  trailing: StatusChip(
                    label: sa.active ? l.active : l.inactive,
                    color: sa.active
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF9E9E9E),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _AdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final store = context.watch<HotelStore>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.hotelSettings,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.sizeOf(context).width >= 900 ? 4 : 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.4,
              children: [
                KpiCard(
                  label: l.roomTypes,
                  value: '${store.roomTypes.length}',
                  icon: Icons.bed_outlined,
                  color: const Color(0xFF9A6A12),
                ),
                KpiCard(
                  label: l.allRooms,
                  value: '${store.rooms.length}',
                  icon: Icons.meeting_room_outlined,
                  color: const Color(0xFF1565C0),
                ),
                KpiCard(
                  label: l.servicesCatalog,
                  value: '${store.services.length}',
                  icon: Icons.room_service_outlined,
                  color: const Color(0xFF2E7D32),
                ),
                KpiCard(
                  label: l.users,
                  value: '${store.users.length}',
                  icon: Icons.people_outline,
                  color: const Color(0xFF6A1B9A),
                ),
                KpiCard(
                  label: l.reservations,
                  value: '${store.reservations.length}',
                  icon: Icons.book_outlined,
                  color: const Color(0xFFAD1457),
                ),
                KpiCard(
                  label: l.inHouse,
                  value: '${store.activeStays.length}',
                  icon: Icons.bed,
                  color: const Color(0xFFEF6C00),
                ),
                KpiCard(
                  label: l.auditLog,
                  value: '${store.audit.length}',
                  icon: Icons.history,
                  color: const Color(0xFF00838F),
                ),
                KpiCard(
                  label: l.availableRooms,
                  value:
                      '${store.rooms.where((r) => r.status.isSellable).length}',
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF5C6B5A),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SectionCard(
              title: l.hotelSettings,
              child: Column(
                children: [
                  _row(
                    context,
                    l.isArabic ? 'الاسم' : 'Name',
                    store.hotel.name,
                  ),
                  _row(context, l.email, store.hotel.email),
                  _row(context, l.phone, store.hotel.phone),
                  _row(
                    context,
                    l.isArabic ? 'العنوان' : 'Address',
                    l.isArabic ? store.hotel.addressAr : store.hotel.address,
                  ),
                  _row(context, l.checkInDate, store.hotel.checkInTime),
                  _row(context, l.checkOutDate, store.hotel.checkOutTime),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String k, String v) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.65),
              ),
            ),
          ),
          Text(v, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _RoomTypesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final store = context.watch<HotelStore>();
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.roomTypes, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 14),
            ...store.roomTypes.map((t) {
              final count = store.rooms
                  .where((r) => r.roomTypeId == t.id)
                  .length;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: RoomImage(
                            palette: t.palette,
                            icon: t.icon,
                            height: 64,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.isArabic ? t.nameAr : t.name,
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(
                              '${t.bedConfig} • ${t.maxOccupancy} ${l.isArabic ? "نزيل" : "guests"} • ${t.sizeSqm}m²',
                            ),
                            Text(
                              '$count ${l.allRooms} • ${Fmt.moneyShort(t.basePrice)} ${l.perNight}',
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.bed_outlined,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ServicesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final store = context.watch<HotelStore>();
    final theme = Theme.of(context);
    final byCat = <ServiceCategory, List<Service>>{};
    for (final s in store.services) {
      byCat.putIfAbsent(s.category, () => []).add(s);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.servicesCatalog, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 14),
            ...ServiceCategory.values.map((c) {
              final items = byCat[c] ?? [];
              if (items.isEmpty) return const SizedBox();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      l.isArabic ? c.labelAr : c.label,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  ...items.map(
                    (s) => Card(
                      child: ListTile(
                        leading: Icon(c.icon, color: theme.colorScheme.primary),
                        title: Text(l.isArabic ? s.nameAr : s.name),
                        subtitle: Text(
                          s.description ??
                              (s.price != null ? Fmt.money(s.price!) : c.label),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _UsersPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final store = context.watch<HotelStore>();
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.users, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 14),
            ...store.users.map(
              (u) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      u.role == 'admin'
                          ? Icons.admin_panel_settings
                          : Icons.support_agent,
                    ),
                  ),
                  title: Text(u.name),
                  subtitle: Text('@${u.username} • ${u.role}'),
                  trailing: StatusChip(
                    label: u.active ? 'active' : 'inactive',
                    color: u.active
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF9E9E9E),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final store = context.watch<HotelStore>();
    final theme = Theme.of(context);
    final entries = store.audit;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.auditTrail, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 14),
            if (entries.isEmpty)
              EmptyState(icon: Icons.history, message: l.noResults)
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: entries
                        .map(
                          (e) => ListTile(
                            leading: Icon(
                              Icons.history,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            title: Text(
                              '${e.action} → ${e.target}',
                              style: theme.textTheme.titleSmall,
                            ),
                            subtitle: Text(
                              '${e.detail ?? ""} • ${e.actor} • ${Fmt.dateTime(e.at)}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

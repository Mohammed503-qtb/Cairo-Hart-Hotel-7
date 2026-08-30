import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hotel_platform/core/app_state.dart';
import 'package:hotel_platform/core/constants.dart';
import 'package:hotel_platform/core/utils/format.dart';
import 'package:hotel_platform/core/utils/responsive.dart';
import 'package:hotel_platform/data/models.dart';
import 'package:hotel_platform/data/store.dart';
import 'package:hotel_platform/l10n/app_localizations.dart';
import 'package:hotel_platform/shared/widgets/common_widgets.dart';

class ReceptionShell extends StatefulWidget {
  const ReceptionShell({super.key});

  @override
  State<ReceptionShell> createState() => _ReceptionShellState();
}

class _ReceptionShellState extends State<ReceptionShell> {
  int _index = 0;

  static final _pages = [
    _DashboardPage(),
    _ArrivalsPage(),
    _DeparturesPage(),
    _InHousePage(),
    _ReservationsPage(),
    _RoomsBoardPage(),
    _RequestsCenterPage(),
  ];

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final app = context.watch<AppState>();
    final isWide = context.isDesktop;
    final tabs = [
      _Tab(l.dashboard, Icons.dashboard_outlined),
      _Tab(l.arrivals, Icons.login),
      _Tab(l.departures, Icons.logout),
      _Tab(l.inHouse, Icons.bed),
      _Tab(l.reservations, Icons.book_outlined),
      _Tab(l.roomsBoard, Icons.grid_view_outlined),
      _Tab(l.requests, Icons.support_agent),
    ];
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(
              Icons.support_agent,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(l.appName, style: const TextStyle(fontSize: 17)),
            const SizedBox(width: 10),
            const Text('·', style: TextStyle(color: Colors.grey)),
            const SizedBox(width: 10),
            Text(l.reception, style: Theme.of(context).textTheme.bodyMedium),
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
              app.signOutStaff();
              context.go('/');
            },
            tooltip: l.logout,
          ),
        ],
      ),
      body: isWide
          ? Row(
              children: [
                NavigationRail(
                  extended: context.isWide,
                  selectedIndex: _index,
                  onDestinationSelected: _go,
                  minExtendedWidth: 200,
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
              selectedIndex: _index > 3 ? 0 : _index,
              onDestinationSelected: _go,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.dashboard_outlined),
                  label: l.dashboard,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.login),
                  label: l.arrivals,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.logout),
                  label: l.departures,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.bed),
                  label: l.inHouse,
                ),
              ],
            ),
      drawer: isWide
          ? null
          : Drawer(
              child: ListView(
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF6C00).withOpacity(0.1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(
                          Icons.support_agent,
                          size: 36,
                          color: Color(0xFFEF6C00),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l.reception,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          l.appName,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  ...tabs.asMap().entries.map(
                    (e) => ListTile(
                      selected: _index == e.key,
                      leading: Icon(e.value.icon),
                      title: Text(e.value.label),
                      onTap: () {
                        Navigator.of(context).pop();
                        _go(e.key);
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Tab {
  final String label;
  final IconData icon;
  const _Tab(this.label, this.icon);
}

// ============================================================
//  DASHBOARD
// ============================================================
class _DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final store = context.watch<HotelStore>();
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final occupied = store.rooms
        .where((r) => r.status == RoomStatus.occupied)
        .length;
    final available = store.rooms.where((r) => r.status.isSellable).length;
    final arrivals = store.reservations
        .where(
          (r) =>
              r.status == ReservationStatus.confirmed &&
              r.checkIn.year == today.year &&
              r.checkIn.month == today.month &&
              r.checkIn.day == today.day,
        )
        .length;
    final departures = store.stays
        .where(
          (s) =>
              s.status == StayStatus.inHouse &&
              s.checkOut.year == today.year &&
              s.checkOut.month == today.month &&
              s.checkOut.day == today.day,
        )
        .length;
    final pendingReqs = store.requests
        .where(
          (r) =>
              r.status == RequestStatus.newRequest ||
              r.status == RequestStatus.acknowledged ||
              r.status == RequestStatus.assigned,
        )
        .length;
    final inProgress = store.requests
        .where((r) => r.status == RequestStatus.inProgress)
        .length;
    final occupancy = store.rooms.isEmpty
        ? 0.0
        : (occupied / store.rooms.length * 100);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.dashboard,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.sizeOf(context).width >= 900 ? 4 : 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.5,
              children: [
                KpiCard(
                  label: l.occupancy,
                  value: '${occupancy.toStringAsFixed(0)}%',
                  icon: Icons.dashboard,
                  color: const Color(0xFF9A6A12),
                ),
                KpiCard(
                  label: l.availableRooms,
                  value: '$available',
                  icon: Icons.bed_outlined,
                  color: const Color(0xFF2E7D32),
                  subtitle: '${store.rooms.length} ${l.allRooms}',
                ),
                KpiCard(
                  label: l.arrivals,
                  value: '$arrivals',
                  icon: Icons.login,
                  color: const Color(0xFF1565C0),
                ),
                KpiCard(
                  label: l.departures,
                  value: '$departures',
                  icon: Icons.logout,
                  color: const Color(0xFFEF6C00),
                ),
                KpiCard(
                  label: l.pendingRequests,
                  value: '$pendingReqs',
                  icon: Icons.support_agent,
                  color: const Color(0xFF6A1B9A),
                ),
                KpiCard(
                  label: l.isArabic ? 'طلبات قيد التنفيذ' : 'In progress',
                  value: '$inProgress',
                  icon: Icons.autorenew,
                  color: const Color(0xFF00838F),
                ),
                KpiCard(
                  label: l.inHouse,
                  value: '${store.activeStays.length}',
                  icon: Icons.people_outline,
                  color: const Color(0xFF5C6B5A),
                ),
                KpiCard(
                  label: l.reservations,
                  value: '${store.reservations.length}',
                  icon: Icons.book_outlined,
                  color: const Color(0xFFAD1457),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _TodayArrivals()),
                const SizedBox(width: 16),
                Expanded(child: _RecentRequests()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayArrivals extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final store = context.watch<HotelStore>();
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final arrivals = store.reservations
        .where(
          (r) =>
              r.status == ReservationStatus.confirmed &&
              r.checkIn.year == today.year &&
              r.checkIn.month == today.month &&
              r.checkIn.day == today.day,
        )
        .toList();
    return SectionCard(
      title: l.arrivals,
      actionLabel: l.isArabic ? 'عرض الكل' : 'View all',
      onAction: () {},
      child: arrivals.isEmpty
          ? EmptyState(icon: Icons.login, message: l.noArrivals)
          : Column(
              children: arrivals.map((r) {
                final g = store.guestById(r.guestId);
                final t = store.roomTypeById(r.roomTypeId)!;
                return ListTile(
                  onTap: () => context.push('/reception/reservation/${r.id}'),
                  leading: const Icon(Icons.person_outline),
                  title: Text(g?.name ?? ''),
                  subtitle: Text('${r.id} • ${l.isArabic ? t.nameAr : t.name}'),
                  trailing: const Icon(Icons.chevron_right),
                );
              }).toList(),
            ),
    );
  }
}

class _RecentRequests extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final store = context.watch<HotelStore>();
    final recent = store.requests.take(5).toList();
    return SectionCard(
      title: l.requests,
      child: recent.isEmpty
          ? EmptyState(icon: Icons.support_agent, message: l.noRequestsYet)
          : Column(
              children: recent.map((r) {
                final room = store.roomById(r.roomId);
                return ListTile(
                  onTap: () => context.push('/reception/request/${r.id}'),
                  leading: Icon(r.category.icon, color: r.status.color),
                  title: Text(r.title),
                  subtitle: Text('${l.roomLabel} ${room?.number} • ${r.id}'),
                  trailing: StatusChip(
                    label: r.status.label,
                    color: r.status.color,
                  ),
                );
              }).toList(),
            ),
    );
  }
}

// ============================================================
//  ARRIVALS
// ============================================================
class _ArrivalsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final store = context.watch<HotelStore>();
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final arrivals = store.reservations
        .where(
          (r) =>
              (r.status == ReservationStatus.confirmed ||
                  r.status == ReservationStatus.pending) &&
              r.checkIn.year == today.year &&
              r.checkIn.month == today.month &&
              r.checkIn.day == today.day,
        )
        .toList();
    return ScaffoldPage(
      title: l.arrivals,
      child: arrivals.isEmpty
          ? EmptyState(icon: Icons.login, message: l.noArrivals)
          : Column(
              children: arrivals.map((r) => _ReservationTile(res: r)).toList(),
            ),
    );
  }
}

class _ReservationTile extends StatelessWidget {
  final Reservation res;
  const _ReservationTile({required this.res});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final store = context.watch<HotelStore>();
    final theme = Theme.of(context);
    final g = store.guestById(res.guestId);
    final t = store.roomTypeById(res.roomTypeId)!;
    final room = res.assignedRoomId == null
        ? null
        : store.roomById(res.assignedRoomId!);
    return Card(
      child: InkWell(
        onTap: () => context.push('/reception/reservation/${res.id}'),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: RoomImage(
                    palette: t.palette,
                    icon: t.icon,
                    height: 56,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g?.name ?? '', style: theme.textTheme.titleMedium),
                    Text(
                      '${res.id} • ${l.isArabic ? t.nameAr : t.name} • ${Fmt.dateShort(res.checkIn)} → ${Fmt.dateShort(res.checkOut)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        StatusChip(
                          label: res.status.label,
                          color: const Color(0xFF1565C0),
                        ),
                        if (room != null)
                          StatusChip(
                            label: '${l.roomLabel} ${room.number}',
                            color: const Color(0xFF2E7D32),
                          ),
                        StatusChip(
                          label: Fmt.money(res.price.total),
                          color: const Color(0xFF9A6A12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  DEPARTURES
// ============================================================
class _DeparturesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final store = context.watch<HotelStore>();
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final deps = store.stays
        .where(
          (s) =>
              (s.status == StayStatus.inHouse ||
                  s.status == StayStatus.checkoutPending) &&
              s.checkOut.year == today.year &&
              s.checkOut.month == today.month &&
              s.checkOut.day == today.day,
        )
        .toList();
    return ScaffoldPage(
      title: l.departures,
      child: deps.isEmpty
          ? EmptyState(icon: Icons.logout, message: l.noDepartures)
          : Column(
              children: deps.map((s) {
                final g = store.guestById(s.guestId);
                final room = store.roomById(s.roomId);
                final balance = store.outstandingBalance(s.id);
                return Card(
                  child: ListTile(
                    onTap: () => context.push('/reception/checkout/${s.id}'),
                    leading: Icon(Icons.logout, color: s.status.color),
                    title: Text(g?.name ?? ''),
                    subtitle: Text('${l.roomLabel} ${room?.number} • ${s.id}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        StatusChip(
                          label: s.status.label,
                          color: s.status.color,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Fmt.money(balance),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: balance > 0
                                    ? const Color(0xFFEF6C00)
                                    : const Color(0xFF2E7D32),
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

// ============================================================
//  IN-HOUSE
// ============================================================
class _InHousePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final store = context.watch<HotelStore>();
    final list = store.activeStays;
    return ScaffoldPage(
      title: l.inHouse,
      child: list.isEmpty
          ? EmptyState(icon: Icons.bed, message: l.noInHouse)
          : Column(
              children: list.map((s) {
                final g = store.guestById(s.guestId);
                final room = store.roomById(s.roomId);
                final t = store.roomTypeById(room!.roomTypeId)!;
                return Card(
                  child: ListTile(
                    onTap: () => context.push('/reception/checkout/${s.id}'),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: RoomImage(
                          palette: t.palette,
                          icon: t.icon,
                          height: 50,
                        ),
                      ),
                    ),
                    title: Text(g?.name ?? ''),
                    subtitle: Text(
                      '${l.roomLabel} ${room.number} • ${l.isArabic ? t.nameAr : t.name} • → ${Fmt.dateShort(s.checkOut)}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        StatusChip(
                          label: s.status.label,
                          color: s.status.color,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Fmt.money(store.outstandingBalance(s.id)),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

// ============================================================
//  RESERVATIONS
// ============================================================
class _ReservationsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final store = context.watch<HotelStore>();
    final list = store.reservations;
    return ScaffoldPage(
      title: l.reservations,
      child: list.isEmpty
          ? EmptyState(icon: Icons.book_outlined, message: l.noResults)
          : Column(
              children: list.map((r) => _ReservationTile(res: r)).toList(),
            ),
    );
  }
}

// ============================================================
//  ROOMS BOARD
// ============================================================
class _RoomsBoardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final store = context.watch<HotelStore>();
    final theme = Theme.of(context);
    final byFloor = <int, List<Room>>{};
    for (final r in store.rooms) {
      byFloor.putIfAbsent(r.floor, () => []).add(r);
    }
    final floors = byFloor.keys.toList()..sort();
    return ScaffoldPage(
      title: l.roomsBoard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: RoomStatus.values
                .map((s) => StatusChip(label: s.label, color: s.color))
                .toList(),
          ),
          const SizedBox(height: 16),
          ...floors.map((f) {
            final rooms = byFloor[f]!
              ..sort((a, b) => a.number.compareTo(b.number));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${l.floor} $f', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: MediaQuery.sizeOf(context).width >= 900
                      ? 8
                      : 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.85,
                  children: rooms.map((r) {
                    final t = store.roomTypeById(r.roomTypeId)!;
                    return Card(
                      color: r.status.color.withOpacity(0.08),
                      child: InkWell(
                        onTap: () => _showRoomActions(context, r),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(t.icon, color: r.status.color, size: 22),
                              const SizedBox(height: 4),
                              Text(
                                r.number,
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                r.status.label,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: r.status.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            );
          }),
        ],
      ),
    );
  }

  void _showRoomActions(BuildContext context, Room r) {
    final l = L10n.of(context);
    final store = context.read<HotelStore>();
    final app = context.read<AppState>();
    final t = store.roomTypeById(r.roomTypeId)!;
    final stay = r.currentStayId == null
        ? null
        : store.stayById(r.currentStayId!);
    showModalBottomSheet(
      context: context,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${r.number} • ${l.isArabic ? t.nameAr : t.name}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text('${l.floor} ${r.floor} • ${r.status.label}'),
              const SizedBox(height: 6),
              if (stay != null) ...[
                Text('${store.guestById(stay.guestId)?.name} • ${stay.id}'),
                Text('→ ${Fmt.dateShort(stay.checkOut)}'),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (r.status == RoomStatus.dirty)
                    ActionChip(
                      label: Text(
                        l.isArabic ? 'بدء التنظيف' : 'Start cleaning',
                      ),
                      onPressed: () {
                        store.updateRoomStatus(
                          r.id,
                          RoomStatus.cleaning,
                          'reception',
                        );
                        Navigator.pop(c);
                      },
                    ),
                  if (r.status == RoomStatus.cleaning)
                    ActionChip(
                      label: Text(l.isArabic ? 'تم التنظيف' : 'Mark clean'),
                      onPressed: () {
                        store.updateRoomStatus(
                          r.id,
                          RoomStatus.clean,
                          'reception',
                        );
                        Navigator.pop(c);
                      },
                    ),
                  if (r.status == RoomStatus.clean ||
                      r.status == RoomStatus.inspected)
                    ActionChip(
                      label: Text(l.isArabic ? 'متاحة' : 'Make available'),
                      onPressed: () {
                        store.updateRoomStatus(
                          r.id,
                          RoomStatus.available,
                          'reception',
                        );
                        Navigator.pop(c);
                      },
                    ),
                  if (r.status != RoomStatus.outOfOrder)
                    ActionChip(
                      label: Text(l.isArabic ? 'تعطيل' : 'Out of order'),
                      onPressed: () {
                        store.updateRoomStatus(
                          r.id,
                          RoomStatus.outOfOrder,
                          'reception',
                        );
                        Navigator.pop(c);
                      },
                    ),
                  if (r.status == RoomStatus.outOfOrder)
                    ActionChip(
                      label: Text(l.isArabic ? 'إعادة تفعيل' : 'Re-activate'),
                      onPressed: () {
                        store.updateRoomStatus(
                          r.id,
                          RoomStatus.available,
                          'reception',
                        );
                        Navigator.pop(c);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  REQUESTS CENTER
// ============================================================
class _RequestsCenterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final store = context.watch<HotelStore>();
    final theme = Theme.of(context);
    final groups = <RequestStatus, List<GuestRequest>>{};
    for (final r in store.requests) {
      groups.putIfAbsent(r.status, () => []).add(r);
    }
    final columns = [
      RequestStatus.newRequest,
      RequestStatus.acknowledged,
      RequestStatus.inProgress,
      RequestStatus.completed,
    ];
    return ScaffoldPage(
      title: l.requests,
      child: MediaQuery.sizeOf(context).width >= 900
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: columns
                  .map(
                    (c) => Expanded(
                      child: _RequestColumn(status: c, items: groups[c] ?? []),
                    ),
                  )
                  .toList(),
            )
          : DefaultTabController(
              length: columns.length,
              child: Column(
                children: [
                  TabBar(
                    isScrollable: true,
                    tabs: columns
                        .map(
                          (c) => Tab(
                            text: '${c.label} (${groups[c]?.length ?? 0})',
                          ),
                        )
                        .toList(),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: columns
                          .map(
                            (c) => ListView(
                              padding: const EdgeInsets.all(12),
                              children: (groups[c] ?? [])
                                  .map((r) => _RequestCard(r))
                                  .toList(),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _RequestColumn extends StatelessWidget {
  final RequestStatus status;
  final List<GuestRequest> items;
  const _RequestColumn({required this.status, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: status.color.withOpacity(0.12),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    status.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: status.color,
                    ),
                  ),
                ),
                Text(
                  '${items.length}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: status.color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _RequestCard(r),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final GuestRequest r;
  const _RequestCard(this.r);

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final store = context.watch<HotelStore>();
    final theme = Theme.of(context);
    final room = store.roomById(r.roomId);
    return Card(
      child: InkWell(
        onTap: () => context.push('/reception/request/${r.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(r.category.icon, color: r.status.color, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(r.title, style: theme.textTheme.titleSmall),
                  ),
                  StatusChip(label: r.status.label, color: r.status.color),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${l.roomLabel} ${room?.number} • ${r.id} • ${Fmt.time(r.createdAt)}',
                style: theme.textTheme.bodySmall,
              ),
              if (r.priority == RequestPriority.urgent)
                const StatusChip(label: 'Urgent', color: Color(0xFFC62828)),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  Shared page scaffold
// ============================================================
class ScaffoldPage extends StatelessWidget {
  final String title;
  final Widget child;
  const ScaffoldPage({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

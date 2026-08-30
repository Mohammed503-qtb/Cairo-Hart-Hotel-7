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

class GuestShell extends StatefulWidget {
  const GuestShell({super.key});

  @override
  State<GuestShell> createState() => _GuestShellState();
}

class _GuestShellState extends State<GuestShell> {
  int _index = 0;

  static const _pages = [
    _StayPage(),
    _RequestsPage(),
    _GuestNotificationsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final app = context.watch<AppState>();
    final store = context.watch<HotelStore>();
    final stay = store.currentStayForGuest(app.guestId!);
    if (stay == null) {
      // Session lost / closed — go back to role selection.
      return Scaffold(
        body: EmptyState(
          icon: Icons.logout,
          message: l.isArabic ? 'لا توجد إقامة نشطة' : 'No active stay',
          action: l.switchSpace,
          onAction: () {
            app.signOutGuest();
            context.go('/');
          },
        ),
      );
    }
    final isWide = context.isDesktop;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l.logout,
            onPressed: () {
              app.signOutGuest();
              context.go('/');
            },
          ),
        ],
      ),
      drawer: isWide
          ? null
          : Drawer(
              child: _GuestDrawer(
                onItem: (i) {
                  Navigator.of(context).pop();
                  setState(() => _index = i);
                },
                onServices: () {
                  Navigator.of(context).pop();
                  context.push('/guest/services');
                },
                onExtend: () {
                  Navigator.of(context).pop();
                  context.push('/guest/extend');
                },
                onRoomChange: () {
                  Navigator.of(context).pop();
                  context.push('/guest/roomchange');
                },
                onCheckout: () {
                  Navigator.of(context).pop();
                  context.push('/guest/checkout');
                },
                onChat: () {
                  Navigator.of(context).pop();
                  context.push('/guest/chat');
                },
                onBill: () {
                  Navigator.of(context).pop();
                  context.push('/guest/bill');
                },
              ),
            ),
      body: isWide
          ? Row(
              children: [
                _GuestNavRail(
                  index: _index,
                  onItem: (i) => setState(() => _index = i),
                  onServices: () => context.push('/guest/services'),
                  onExtend: () => context.push('/guest/extend'),
                  onRoomChange: () => context.push('/guest/roomchange'),
                  onCheckout: () => context.push('/guest/checkout'),
                  onChat: () => context.push('/guest/chat'),
                  onBill: () => context.push('/guest/bill'),
                ),
                Expanded(child: IndexedStack(index: _index, children: _pages)),
              ],
            )
          : IndexedStack(index: _index, children: _pages),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/guest/services'),
        icon: const Icon(Icons.add),
        label: Text(l.requestService),
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                NavigationDestination(
                    icon: const Icon(Icons.bed_outlined),
                    selectedIcon: const Icon(Icons.bed),
                    label: l.myStay),
                NavigationDestination(
                    icon: const Icon(Icons.task_outlined),
                    selectedIcon: const Icon(Icons.task),
                    label: l.requests),
                NavigationDestination(
                    icon: const Icon(Icons.notifications_outlined),
                    selectedIcon: const Icon(Icons.notifications),
                    label: l.notifications),
              ],
            ),
    );
  }
}

class _GuestDrawer extends StatelessWidget {
  final ValueChanged<int> onItem;
  final VoidCallback onServices, onExtend, onRoomChange, onCheckout, onChat, onBill;
  const _GuestDrawer({
    required this.onItem,
    required this.onServices,
    required this.onExtend,
    required this.onRoomChange,
    required this.onCheckout,
    required this.onChat,
    required this.onBill,
  });

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return ListView(
      children: [
        DrawerHeader(
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.hotel, color: Theme.of(context).colorScheme.primary, size: 36),
              const SizedBox(height: 6),
              Text(l.appName, style: Theme.of(context).textTheme.titleLarge),
              Text(l.guestApp, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        ListTile(leading: const Icon(Icons.bed_outlined), title: Text(l.myStay), onTap: () => onItem(0)),
        ListTile(leading: const Icon(Icons.task_outlined), title: Text(l.requests), onTap: () => onItem(1)),
        ListTile(leading: const Icon(Icons.add_circle_outline), title: Text(l.requestService), onTap: onServices),
        const Divider(),
        ListTile(leading: const Icon(Icons.support_agent), title: Text(l.receptionChat), onTap: onChat),
        ListTile(leading: const Icon(Icons.receipt_long_outlined), title: Text(l.myBill), onTap: onBill),
        ListTile(leading: const Icon(Icons.update), title: Text(l.extendStay), onTap: onExtend),
        ListTile(leading: const Icon(Icons.swap_horiz), title: Text(l.roomChange), onTap: onRoomChange),
        ListTile(leading: const Icon(Icons.logout), title: Text(l.checkoutRequest), onTap: onCheckout),
        ListTile(leading: const Icon(Icons.notifications_outlined), title: Text(l.notifications), onTap: () => onItem(2)),
      ],
    );
  }
}

class _GuestNavRail extends StatelessWidget {
  final int index;
  final ValueChanged<int> onItem;
  final VoidCallback onServices, onExtend, onRoomChange, onCheckout, onChat, onBill;
  const _GuestNavRail({
    required this.index,
    required this.onItem,
    required this.onServices,
    required this.onExtend,
    required this.onRoomChange,
    required this.onCheckout,
    required this.onChat,
    required this.onBill,
  });

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return Container(
      width: 240,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.hotel, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(l.appName, style: Theme.of(context).textTheme.titleMedium, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _railItem(context, 0, Icons.bed_outlined, l.myStay),
                _railItem(context, 1, Icons.task_outlined, l.requests),
                _railAction(context, Icons.add_circle_outline, l.requestService, onServices),
                const Divider(),
                _railAction(context, Icons.support_agent, l.receptionChat, onChat),
                _railAction(context, Icons.receipt_long_outlined, l.myBill, onBill),
                _railAction(context, Icons.update, l.extendStay, onExtend),
                _railAction(context, Icons.swap_horiz, l.roomChange, onRoomChange),
                _railAction(context, Icons.logout, l.checkoutRequest, onCheckout),
                _railItem(context, 2, Icons.notifications_outlined, l.notifications),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _railItem(BuildContext context, int i, IconData icon, String label) {
    final sel = index == i;
    final theme = Theme.of(context);
    return ListTile(
      selected: sel,
      selectedTileColor: theme.colorScheme.primary.withOpacity(0.12),
      leading: Icon(icon,
          color: sel ? theme.colorScheme.primary : null),
      title: Text(label, style: TextStyle(fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
      onTap: () => onItem(i),
    );
  }

  Widget _railAction(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary.withOpacity(0.85)),
      title: Text(label),
      onTap: onTap,
    );
  }
}

// ============================================================
//  STAY HOME
// ============================================================
class _StayPage extends StatelessWidget {
  const _StayPage();

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final app = context.watch<AppState>();
    final store = context.watch<HotelStore>();
    final theme = Theme.of(context);
    final stay = store.currentStayForGuest(app.guestId!)!;
    final room = store.roomById(stay.roomId)!;
    final type = store.roomTypeById(room.roomTypeId)!;
    final guest = store.guestById(stay.guestId)!;
    final nights = Fmt.nights(stay.checkIn, stay.checkOut);
    final access = store.firstWhereOrNull(store.accesses, (a) => a.stayId == stay.id);
    final balance = store.outstandingBalance(stay.id);
    final reqs = store.requestsForStay(stay.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero stay card
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RoomImage(palette: type.palette, icon: type.icon, height: 150),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l.welcomeGuest} ${guest.name}',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${l.roomLabel} ${room.number} • ${l.isArabic ? type.nameAr : type.name}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            StatusChip(label: stay.status.label, color: stay.status.color),
                            const SizedBox(width: 8),
                            StatusChip(
                              label: '${Fmt.dateShort(stay.checkIn)} → ${Fmt.dateShort(stay.checkOut)}',
                              color: theme.colorScheme.primary,
                              icon: Icons.calendar_today_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$nights ${nights == 1 ? l.night : l.nights} • ${l.checkOutDate} ${Fmt.dateShort(stay.checkOut)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (access != null)
              Card(
                color: theme.colorScheme.primary.withOpacity(0.08),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.vpn_key, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.accessCodeReady, style: theme.textTheme.titleSmall),
                            Text(
                              access.code,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                letterSpacing: 6,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Quick actions
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.sizeOf(context).width >= 600 ? 4 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: [
                _QuickAction(icon: Icons.room_service_outlined, label: l.requestService, onTap: () => context.push('/guest/services')),
                _QuickAction(icon: Icons.support_agent, label: l.receptionChat, onTap: () => context.push('/guest/chat')),
                _QuickAction(icon: Icons.receipt_long_outlined, label: l.myBill, onTap: () => context.push('/guest/bill')),
                _QuickAction(icon: Icons.update, label: l.extendStay, onTap: () => context.push('/guest/extend')),
                _QuickAction(icon: Icons.swap_horiz, label: l.roomChange, onTap: () => context.push('/guest/roomchange')),
                _QuickAction(icon: Icons.logout, label: l.checkoutRequest, onTap: () => context.push('/guest/checkout')),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(l.requests, style: theme.textTheme.titleLarge),
                const Spacer(),
                Text('${reqs.length}', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
              ],
            ),
            const SizedBox(height: 8),
            if (reqs.isEmpty)
              EmptyState(icon: Icons.task_outlined, message: l.noRequestsYet)
            else
              ...reqs.take(3).map((r) => _RequestTile(r: r, onTap: () => context.push('/guest/request/${r.id}'))),
            const SizedBox(height: 16),
            SectionCard(
              title: l.outstandingBalance,
              child: Row(
                children: [
                  Expanded(
                    child: Text(Fmt.money(balance),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: balance > 0 ? const Color(0xFFEF6C00) : const Color(0xFF2E7D32),
                          fontWeight: FontWeight.w800,
                        )),
                  ),
                  TextButton(onPressed: () => context.push('/guest/bill'), child: Text(l.myBill)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 28),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center, style: theme.textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final GuestRequest r;
  final VoidCallback onTap;
  const _RequestTile({required this.r, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = L10n.of(context);
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(r.category.icon, color: r.status.color),
        title: Text(r.title, style: theme.textTheme.titleSmall),
        subtitle: Text(
          '${l.requestNo} ${r.id} • ${Fmt.dateTime(r.createdAt)}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: StatusChip(label: r.status.label, color: r.status.color),
      ),
    );
  }
}

// ============================================================
//  REQUESTS LIST PAGE
// ============================================================
class _RequestsPage extends StatelessWidget {
  const _RequestsPage();

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final app = context.watch<AppState>();
    final store = context.watch<HotelStore>();
    final reqs = store.requestsForGuest(app.guestId!);
    return Scaffold(
      appBar: AppBar(title: Text(l.requests)),
      body: reqs.isEmpty
          ? EmptyState(
              icon: Icons.task_outlined,
              message: l.noRequestsYet,
              action: l.requestService,
              onAction: () => context.push('/guest/services'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reqs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (c, i) {
                final r = reqs[i];
                return _RequestTile(r: r, onTap: () => context.push('/guest/request/${r.id}'));
              },
            ),
    );
  }
}

// ============================================================
//  NOTIFICATIONS PAGE (guest)
// ============================================================
class _GuestNotificationsPage extends StatelessWidget {
  const _GuestNotificationsPage();

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final app = context.watch<AppState>();
    final store = context.watch<HotelStore>();
    final notifs = store.notificationsForGuest(app.guestId!);
    return Scaffold(
      appBar: AppBar(title: Text(l.notifications)),
      body: notifs.isEmpty
          ? EmptyState(icon: Icons.notifications_outlined, message: l.isArabic ? 'لا إشعارات' : 'No notifications')
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (c, i) {
                final n = notifs[i];
                return Card(
                  child: ListTile(
                    leading: Icon(Icons.notifications_active_outlined,
                        color: Theme.of(context).colorScheme.primary),
                    title: Text(n.title),
                    subtitle: Text('${n.body}\n${Fmt.dateTime(n.at)}'),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}

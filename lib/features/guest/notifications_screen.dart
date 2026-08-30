import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hotel_platform/core/app_state.dart';
import 'package:hotel_platform/core/utils/format.dart';
import 'package:hotel_platform/data/store.dart';
import 'package:hotel_platform/l10n/app_localizations.dart';
import 'package:hotel_platform/shared/widgets/common_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final app = context.watch<AppState>();
    final store = context.watch<HotelStore>();
    final notifs = store.notificationsForGuest(app.guestId!);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l.notifications),
      ),
      body: notifs.isEmpty
          ? EmptyState(
              icon: Icons.notifications_outlined,
              message: l.isArabic ? 'لا إشعارات' : 'No notifications',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (c, i) {
                final n = notifs[i];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.notifications_active_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
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

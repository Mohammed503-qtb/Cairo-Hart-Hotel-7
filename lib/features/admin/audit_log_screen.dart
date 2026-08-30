import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hotel_platform/core/utils/format.dart';
import 'package:hotel_platform/data/store.dart';
import 'package:hotel_platform/l10n/app_localizations.dart';
import 'package:hotel_platform/shared/widgets/common_widgets.dart';

class AuditLogScreen extends StatelessWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final store = context.watch<HotelStore>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text(l.auditLog),
      ),
      body: store.audit.isEmpty
          ? EmptyState(icon: Icons.history, message: l.noResults)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: store.audit.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (c, i) {
                final e = store.audit[i];
                return ListTile(
                  leading: Icon(Icons.history, color: theme.colorScheme.primary),
                  title: Text('${e.action} → ${e.target}', style: theme.textTheme.titleSmall),
                  subtitle: Text('${e.detail ?? ""} • ${e.actor} • ${Fmt.dateTime(e.at)}', style: theme.textTheme.bodySmall),
                );
              },
            ),
    );
  }
}

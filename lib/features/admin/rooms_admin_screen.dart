import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hotel_platform/core/constants.dart';
import 'package:hotel_platform/core/utils/format.dart';
import 'package:hotel_platform/data/models.dart';
import 'package:hotel_platform/data/store.dart';
import 'package:hotel_platform/l10n/app_localizations.dart';
import 'package:hotel_platform/shared/widgets/common_widgets.dart';

class RoomsAdminScreen extends StatelessWidget {
  const RoomsAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final store = context.watch<HotelStore>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l.allRooms),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
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
              ...store.rooms.map((r) {
                final t = store.roomTypeById(r.roomTypeId)!;
                final stay = r.currentStayId == null
                    ? null
                    : store.stayById(r.currentStayId!);
                return Card(
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
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
                    title: Text(
                      '${r.number} • ${l.isArabic ? t.nameAr : t.name}',
                    ),
                    subtitle: Text(
                      '${l.floor} ${r.floor} • ${r.status.label}${stay != null ? " • ${store.guestById(stay.guestId)?.name ?? ""}" : ""}',
                    ),
                    trailing: Wrap(
                      spacing: 6,
                      children: [
                        StatusChip(
                          label: r.status.label,
                          color: r.status.color,
                        ),
                        ActionChip(
                          label: Text(
                            r.active
                                ? l.isArabic
                                      ? 'تعطيل'
                                      : 'Disable'
                                : l.isArabic
                                ? 'تفعيل'
                                : 'Enable',
                          ),
                          onPressed: () => store.adminToggleRoomActive(r.id),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

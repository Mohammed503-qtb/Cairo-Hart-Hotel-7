import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hotel_platform/core/app_state.dart';
import 'package:hotel_platform/core/constants.dart';
import 'package:hotel_platform/core/utils/format.dart';
import 'package:hotel_platform/data/models.dart';
import 'package:hotel_platform/data/store.dart';
import 'package:hotel_platform/l10n/app_localizations.dart';
import 'package:hotel_platform/shared/widgets/common_widgets.dart';

class RoomChangeScreen extends StatefulWidget {
  const RoomChangeScreen({super.key});

  @override
  State<RoomChangeScreen> createState() => _RoomChangeScreenState();
}

class _RoomChangeScreenState extends State<RoomChangeScreen> {
  String? _selectedRoomId;
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final app = context.watch<AppState>();
    final store = context.watch<HotelStore>();
    final theme = Theme.of(context);
    final stay = store.currentStayForGuest(app.guestId!)!;
    final currentRoom = store.roomById(stay.roomId)!;
    final currentType = store.roomTypeById(currentRoom.roomTypeId)!;

    // Available rooms of same or any type for the stay range
    final candidates = store.rooms.where((r) {
      if (r.id == currentRoom.id) return false;
      if (!r.active) return false;
      if (!r.status.isSellable) return false;
      if (store.firstWhereOrNull(
            store.stays,
            (s) =>
                s.roomId == r.id &&
                s.id != stay.id &&
                (s.status == StayStatus.inHouse ||
                    s.status == StayStatus.checkedIn),
          ) !=
          null)
        return false;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l.roomChange),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionCard(
                child: Row(
                  children: [
                    Icon(Icons.bed, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.isArabic ? 'الغرفة الحالية' : 'Current room',
                            style: theme.textTheme.titleSmall,
                          ),
                          Text(
                            '${currentRoom.number} • ${l.isArabic ? currentType.nameAr : currentType.name}',
                            style: theme.textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l.isArabic ? 'اختر غرفة جديدة' : 'Choose a new room',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (candidates.isEmpty)
                EmptyState(
                  icon: Icons.bed_outlined,
                  message: l.isArabic
                      ? 'لا توجد غرف متاحة حالياً'
                      : 'No rooms available right now',
                )
              else
                ...candidates.map((r) {
                  final t = store.roomTypeById(r.roomTypeId)!;
                  final sel = _selectedRoomId == r.id;
                  return Card(
                    color: sel
                        ? theme.colorScheme.primary.withOpacity(0.08)
                        : null,
                    child: ListTile(
                      onTap: () => setState(() => _selectedRoomId = r.id),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
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
                      title: Text(
                        '${r.number} • ${l.isArabic ? t.nameAr : t.name}',
                      ),
                      subtitle: Text(
                        '${l.floor} ${r.floor} • ${Fmt.moneyShort(t.basePrice)} ${l.perNight}',
                      ),
                      trailing: sel
                          ? Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.primary,
                            )
                          : const Icon(Icons.radio_button_unchecked),
                    ),
                  );
                }),
              const SizedBox(height: 16),
              TextField(
                controller: _reasonCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l.reason,
                  hintText: l.isArabic
                      ? 'مثال: مشكلة في التكييف'
                      : 'e.g. AC issue',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _selectedRoomId == null
                      ? null
                      : () => _submit(stay),
                  icon: const Icon(Icons.swap_horiz),
                  label: Text(l.sendRequest),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit(Stay stay) {
    final store = context.read<HotelStore>();
    final l = L10n.of(context);
    final reason = _reasonCtrl.text.trim().isEmpty
        ? (l.isArabic ? 'طلب تغيير من النزيل' : 'Guest requested room change')
        : _reasonCtrl.text.trim();
    store.transferRoom(
      stayId: stay.id,
      newRoomId: _selectedRoomId!,
      reason: reason,
      actor: 'guest',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.isArabic ? 'تم تغيير الغرفة ✓' : 'Room changed ✓'),
      ),
    );
    context.pop();
  }
}

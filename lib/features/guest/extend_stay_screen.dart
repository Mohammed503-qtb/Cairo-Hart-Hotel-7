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

class ExtendStayScreen extends StatefulWidget {
  const ExtendStayScreen({super.key});

  @override
  State<ExtendStayScreen> createState() => _ExtendStayScreenState();
}

class _ExtendStayScreenState extends State<ExtendStayScreen> {
  DateTime? _requested;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final app = context.watch<AppState>();
    final store = context.watch<HotelStore>();
    final theme = Theme.of(context);
    final stay = store.currentStayForGuest(app.guestId!)!;
    final requested = _requested ?? stay.checkOut.add(const Duration(days: 1));
    final type = store.roomTypeById(store.roomById(stay.roomId)!.roomTypeId)!;
    final extraNights = Fmt.nights(stay.checkOut, requested);
    final cost = type.basePrice * extraNights;
    final existing = store.firstWhereOrNull(store.extensionRequests, (e) => e.stayId == stay.id && !e.approved);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text(l.extendStay),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionCard(
                child: Row(
                  children: [
                    Icon(Icons.event_available, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.isArabic ? 'المغادرة الحالية' : 'Current checkout', style: theme.textTheme.titleSmall),
                          Text(Fmt.date(stay.checkOut), style: theme.textTheme.titleLarge),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(l.isArabic ? 'المغادرة المطلوبة' : 'Requested checkout', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final p = await showDatePicker(
                    context: context,
                    initialDate: requested,
                    firstDate: stay.checkOut.add(const Duration(days: 1)),
                    lastDate: stay.checkOut.add(const Duration(days: 30)),
                  );
                  if (p != null) setState(() => _requested = p);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.12)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Text(Fmt.date(requested), style: theme.textTheme.titleMedium),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (extraNights > 0)
                Card(
                  color: theme.colorScheme.primary.withOpacity(0.06),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$extraNights ${extraNights == 1 ? l.night : l.nights} × ${Fmt.moneyShort(type.basePrice)}',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                        Text(Fmt.money(cost), style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(l.requestExtensionMsg, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
              const SizedBox(height: 16),
              if (existing != null)
                Card(
                  color: const Color(0xFFEF6C00).withOpacity(0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(Icons.hourglass_top, color: Color(0xFFEF6C00)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${l.pendingReview} • ${Fmt.dateShort(existing.requestedCheckout)}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: () => _submit(stay),
                    icon: const Icon(Icons.send),
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
    store.requestExtension(stayId: stay.id, requestedCheckout: _requested!);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.isArabic ? 'تم إرسال طلب التمديد ✓' : 'Extension request sent ✓')));
    context.pop();
  }
}

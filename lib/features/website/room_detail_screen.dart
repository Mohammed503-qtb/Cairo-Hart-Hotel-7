import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hotel_platform/core/utils/format.dart';
import 'package:hotel_platform/data/store.dart';
import 'package:hotel_platform/l10n/app_localizations.dart';
import 'package:hotel_platform/shared/widgets/common_widgets.dart';

class RoomDetailScreen extends StatelessWidget {
  final String roomTypeId;
  const RoomDetailScreen({super.key, required this.roomTypeId});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final store = context.watch<HotelStore>();
    final theme = Theme.of(context);
    final type = store.roomTypeById(roomTypeId);
    if (type == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(icon: Icons.error_outline, message: l.noResults),
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l.isArabic ? type.nameAr : type.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RoomImage(palette: type.palette, icon: type.icon, height: 260),
            Padding(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.isArabic ? type.nameAr : type.name,
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${type.bedConfig} • ${type.maxOccupancy} ${l.isArabic ? "نزيل" : "guests"} • ${type.sizeSqm}m²',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SectionCard(
                      title: l.isArabic ? 'الوصف' : 'Description',
                      child: Text(
                        l.isArabic ? type.descriptionAr : type.description,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SectionCard(
                      title: l.amenities,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: type.amenities
                            .map((a) => Chip(label: Text(a)))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SectionCard(
                      title: l.policies,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            (l.isArabic
                                    ? store.hotel.policiesAr
                                    : store.hotel.policies)
                                .map(
                                  (p) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          size: 18,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(p)),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                Fmt.money(type.basePrice),
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${l.perNight}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => context.push(
                            '/website/booking',
                            extra: {
                              'roomTypeId': type.id,
                              'adults': type.defaultAdults,
                            },
                          ),
                          icon: const Icon(Icons.calendar_month_outlined),
                          label: Text(l.checkAvailability),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

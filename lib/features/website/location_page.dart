import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hotel_platform/data/store.dart';
import 'package:hotel_platform/features/website/website_shell.dart';
import 'package:hotel_platform/l10n/app_localizations.dart';
import 'package:hotel_platform/shared/widgets/common_widgets.dart';

/// Location page (PLAN_WEBSITE §16). Where the hotel is and how to arrive.
class LocationPage extends StatelessWidget {
  const LocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final store = context.watch<HotelStore>();
    final theme = Theme.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 800;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.location, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              l.isArabic
                  ? 'أين نحن وكيف تصل إلينا'
                  : 'Where we are and how to reach us',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 18),
            // Map placeholder
            Container(
              height: 260,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1565C0),
                    const Color(0xFF42A5F5),
                    const Color(0xFF90CAF9),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Icon(
                      Icons.map,
                      size: 200,
                      color: Colors.white.withOpacity(0.15),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.place, size: 44, color: Colors.white),
                        const SizedBox(height: 8),
                        Text(
                          l.isArabic
                              ? store.hotel.addressAr
                              : store.hotel.address,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Address + contact
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row(
                    context,
                    Icons.location_on,
                    l.isArabic ? store.hotel.addressAr : store.hotel.address,
                  ),
                  _row(context, Icons.phone, store.hotel.phone),
                  _row(context, Icons.email, store.hotel.email),
                  _row(
                    context,
                    Icons.chat,
                    'WhatsApp +${store.hotel.whatsapp}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Directions / nearby
            Text(
              l.isArabic ? 'كيف تصل إلينا' : 'How to reach us',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isWide ? 2 : 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isWide ? 3 : 2.4,
              children: [
                _DirectionWidget(
                  _Direction(
                    icon: Icons.flight,
                    title: l.isArabic ? 'من المطار' : 'From the airport',
                    desc: l.isArabic
                        ? '25 دقيقة بالسيارة، خدمة نقل متاحة عند الطلب'
                        : '25 minutes by car, transfer available on request',
                  ),
                ),
                _DirectionWidget(
                  _Direction(
                    icon: Icons.directions_car,
                    title: l.isArabic ? 'بالسيارة' : 'By car',
                    desc: l.isArabic
                        ? 'ركن سيارات آمن + فاليه، 24 ساعة'
                        : 'Secure parking + valet, 24/7',
                  ),
                ),
                _DirectionWidget(
                  _Direction(
                    icon: Icons.directions_walk,
                    title: l.isArabic ? 'سيراً على الأقدام' : 'Walking',
                    desc: l.isArabic
                        ? '5 دقائق من كورنيش البحر والمطاعم'
                        : '5 minutes to the seaside promenade & restaurants',
                  ),
                ),
                _DirectionWidget(
                  _Direction(
                    icon: Icons.directions_transit,
                    title: l.isArabic ? 'المواصلات العامة' : 'Public transport',
                    desc: l.isArabic
                        ? 'محطة مترو على بُعد 10 دقائق'
                        : 'Metro station 10 minutes away',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const HotelFooter(),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

class _Direction {
  final IconData icon;
  final String title;
  final String desc;
  const _Direction({
    required this.icon,
    required this.title,
    required this.desc,
  });
}

// ignore: unused_element
class _DirectionWidget extends StatelessWidget {
  final _Direction d;
  const _DirectionWidget(this.d, {super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(d.icon, color: theme.colorScheme.primary, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(d.title, style: theme.textTheme.titleSmall),
                  Text(d.desc, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

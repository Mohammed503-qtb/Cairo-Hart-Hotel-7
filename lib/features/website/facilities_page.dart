import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hotel_platform/data/store.dart';
import 'package:hotel_platform/features/website/website_shell.dart';
import 'package:hotel_platform/l10n/app_localizations.dart';
import 'package:hotel_platform/shared/widgets/common_widgets.dart';

/// Facilities page (PLAN_WEBSITE §10). Lists the hotel's facilities with
/// name, description, image placeholder, hours.
class FacilitiesPage extends StatelessWidget {
  const FacilitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final store = context.watch<HotelStore>();
    final theme = Theme.of(context);
    final facilities = [
      _Facility(
        icon: Icons.pool,
        name: l.isArabic ? 'مسبح السطح اللانهائي' : 'Rooftop Infinity Pool',
        desc: l.isArabic
            ? 'مسبح بانورامي على السطح بإطلالة بحرية كاملة، مفتوح من 7ص حتى 9م.'
            : 'Panoramic rooftop pool with full sea view, open 7am–9pm.',
        hours: '07:00 – 21:00',
        color: const Color(0xFF1565C0),
      ),
      _Facility(
        icon: Icons.fitness_center,
        name: l.isArabic ? 'مركز اللياقة 24 ساعة' : '24h Fitness Center',
        desc: l.isArabic
            ? 'صالة رياضية مجهزة بأحدث الأجهزة، مفتوحة 24 ساعة.'
            : 'State-of-the-art gym equipment, open 24 hours.',
        hours: '24 / 7',
        color: const Color(0xFF2E7D32),
      ),
      _Facility(
        icon: Icons.spa,
        name: l.isArabic ? 'سبا وساونا' : 'Spa & Sauna',
        desc: l.isArabic
            ? 'جلسات تدليك، ساونا، حمام بخار، غرفة استرخاء.'
            : 'Massage sessions, sauna, steam room, relaxation lounge.',
        hours: '10:00 – 22:00',
        color: const Color(0xFF6A1B9A),
      ),
      _Facility(
        icon: Icons.restaurant,
        name: l.isArabic ? 'المطعم واللاونج' : 'Restaurant & Lounge',
        desc: l.isArabic
            ? 'مطبخ عالمي، إفطار بوفيه، عشاء فاخر، لاونج على السطح.'
            : 'International cuisine, buffet breakfast, fine dining, rooftop lounge.',
        hours: '06:30 – 23:00',
        color: const Color(0xFFEF6C00),
      ),
      _Facility(
        icon: Icons.business_center,
        name: l.isArabic
            ? 'مركز الأعمال وقاعات الاجتماعات'
            : 'Business Center & Meeting Rooms',
        desc: l.isArabic
            ? 'غرف اجتماعات مجهزة، Wi-Fi عالي السرعة، خدمات سكرتارية.'
            : 'Equipped meeting rooms, high-speed Wi-Fi, secretarial services.',
        hours: '24 / 7',
        color: const Color(0xFF5C6B5A),
      ),
      _Facility(
        icon: Icons.local_taxi,
        name: l.isArabic ? 'خدمة الفاليه والسيارات' : 'Valet & Parking',
        desc: l.isArabic
            ? 'ركن سيارات آمن، خدمة فاليه، نقل من وإلى المطار (حسب الطلب).'
            : 'Secure parking, valet service, airport transfers on request.',
        hours: '24 / 7',
        color: const Color(0xFF455A64),
      ),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.facilities, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              l.isArabic
                  ? 'كل ما تحتاجه لإقامة مريحة و Experience متكامل'
                  : 'Everything you need for a complete, comfortable stay',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 18),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.sizeOf(context).width >= 800 ? 2 : 1,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 2.4,
              children: facilities
                  .map(
                    (f) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: f.color.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(f.icon, color: f.color, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    f.name,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    f.desc,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.schedule,
                                        size: 14,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        f.hours,
                                        style: theme.textTheme.labelSmall,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            const HotelFooter(),
          ],
        ),
      ),
    );
  }
}

class _Facility {
  final IconData icon;
  final String name;
  final String desc;
  final String hours;
  final Color color;
  const _Facility({
    required this.icon,
    required this.name,
    required this.desc,
    required this.hours,
    required this.color,
  });
}

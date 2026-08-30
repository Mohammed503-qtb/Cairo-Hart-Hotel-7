import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hotel_platform/data/store.dart';
import 'package:hotel_platform/features/website/website_shell.dart';
import 'package:hotel_platform/l10n/app_localizations.dart';
import 'package:hotel_platform/shared/widgets/common_widgets.dart';

/// About page (PLAN_WEBSITE §11). Hotel story, philosophy, identity.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

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
            // Hero
            Container(
              height: 240,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF7D5A3C), const Color(0xFFB8860B)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.hotel,
                      size: 48,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l.appName,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.tagline,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(l.about, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 12),
            SectionCard(
              child: Text(
                l.isArabic
                    ? store.hotel.descriptionAr
                    : store.hotel.description,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
              ),
            ),
            const SizedBox(height: 16),
            // Values
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isWide ? 3 : 1,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: isWide ? 1.4 : 2.2,
              children: [
                _ValueWidget(
                  _Value(
                    icon: Icons.diamond_outlined,
                    title: l.isArabic ? 'ضيافة خالدة' : 'Timeless Hospitality',
                    desc: l.isArabic
                        ? 'تجربة ضيافة أصيلة تجمع بين الفخامة والدفء'
                        : 'Authentic hospitality blending luxury with warmth',
                    color: const Color(0xFFB8860B),
                  ),
                ),
                _ValueWidget(
                  _Value(
                    icon: Icons.location_on_outlined,
                    title: l.isArabic ? 'موقع ساحلي' : 'Seaside Location',
                    desc: l.isArabic
                        ? 'على كورنيش البحر، قريب من كل ما يهمّك'
                        : 'On the seaside boulevard, close to everything',
                    color: const Color(0xFF1565C0),
                  ),
                ),
                _ValueWidget(
                  _Value(
                    icon: Icons.security_outlined,
                    title: l.isArabic ? 'راحة وثقة' : 'Comfort & Trust',
                    desc: l.isArabic
                        ? 'غرف فسيحة، خدمة موثوقة، إقامة هادئة'
                        : 'Spacious rooms, reliable service, peaceful stay',
                    color: const Color(0xFF2E7D32),
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
}

class _Value {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  const _Value({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
  });
}

// `build` for _Value is provided via a separate widget below.
class _ValueWidget extends StatelessWidget {
  final _Value v;
  const _ValueWidget(this.v, {super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(v.icon, color: v.color, size: 28),
            const SizedBox(height: 8),
            Text(v.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(v.desc, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

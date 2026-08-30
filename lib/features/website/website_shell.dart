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
import 'package:hotel_platform/features/website/booking_search_bar.dart';

class WebsiteShell extends StatefulWidget {
  const WebsiteShell({super.key});

  @override
  State<WebsiteShell> createState() => _WebsiteShellState();
}

class _WebsiteShellState extends State<WebsiteShell> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final app = context.watch<AppState>();
    final store = context.watch<HotelStore>();
    final isWide = context.isDesktop;
    final tabs = [
      _Tab(l.home, Icons.home_outlined),
      _Tab(l.rooms, Icons.bed_outlined),
      _Tab(l.gallery, Icons.photo_library_outlined),
      _Tab(l.contact, Icons.contact_support_outlined),
    ];
    final pages = [
      WebsiteHome(onExplore: () => _go(1)),
      const RoomsPage(),
      const GalleryPage(),
      const ContactPage(),
    ];

    Widget body = IndexedStack(index: _index, children: pages);

    NavigationBar bottomBar = NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: _go,
      destinations: tabs
          .map(
            (t) => NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.icon),
              label: t.label,
            ),
          )
          .toList(),
    );

    AppBar topBar = AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          app.setSpace(AppSpace.website);
          context.go('/');
        },
        tooltip: l.switchSpace,
      ),
      title: Row(
        children: [
          Icon(Icons.hotel, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l.appName,
              style: const TextStyle(fontSize: 17),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        if (!isWide)
          Row(
            children: tabs
                .asMap()
                .entries
                .map(
                  (e) => IconButton(
                    icon: Icon(
                      e.value.icon,
                      color: _index == e.key
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    onPressed: () => _go(e.key),
                    tooltip: e.value.label,
                  ),
                )
                .toList(),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: tabs
                  .asMap()
                  .entries
                  .map(
                    (e) => TextButton(
                      onPressed: () => _go(e.key),
                      style: TextButton.styleFrom(
                        foregroundColor: _index == e.key
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface
                                  .withOpacity(0.7),
                      ),
                      child: Text(
                        e.value.label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.translate),
          onPressed: () => app.toggleLocale(),
          tooltip: l.switchLang,
        ),
        IconButton(
          icon: Icon(
            app.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          ),
          onPressed: () => app.setThemeMode(
            app.isDark ? AppThemeMode.light : AppThemeMode.dark,
          ),
          tooltip: l.switchTheme,
        ),
        const SizedBox(width: 6),
      ],
    );

    return Scaffold(
      appBar: topBar,
      body: body,
      bottomNavigationBar: isWide ? null : bottomBar,
    );
  }
}

class _Tab {
  final String label;
  final IconData icon;
  const _Tab(this.label, this.icon);
}

// ============================================================
//  HOME
// ============================================================
class WebsiteHome extends StatelessWidget {
  final VoidCallback onExplore;
  const WebsiteHome({super.key, required this.onExplore});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final store = context.watch<HotelStore>();
    final theme = Theme.of(context);
    final isWide = context.isDesktop;

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: context.height - kToolbarHeight - 80,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero
            Container(
              height: context.isMobile ? 320 : 460,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFB8860B),
                    const Color(0xFF7D5A3C),
                    const Color(0xFF2E2218),
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 80 : 24,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l.appName,
                        style: theme.textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.tagline,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white.withOpacity(0.85),
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: BookingSearchBar(
                          onSearch: () => _openBooking(context, null),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Featured room types
            Padding(
              padding: EdgeInsets.all(isWide ? 40 : 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.selectRoomType,
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.isArabic
                          ? 'اختر من بين أنواع غرفنا المميزة'
                          : 'Choose from our featured room types',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 18),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: isWide ? 3 : (context.isTablet ? 2 : 1),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isWide ? 0.78 : 0.85,
                      children: store.roomTypes
                          .map((t) => RoomTypeCard(type: t))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            // Amenities strip
            Container(
              color: theme.colorScheme.primary.withOpacity(0.06),
              padding: EdgeInsets.symmetric(
                vertical: 28,
                horizontal: isWide ? 80 : 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    _amenity(context, Icons.pool, 'Rooftop pool', l),
                    _amenity(context, Icons.fitness_center, '24h gym', l),
                    _amenity(context, Icons.wifi, 'Free Wi-Fi', l),
                    _amenity(context, Icons.spa, 'Spa & sauna', l),
                    _amenity(context, Icons.restaurant, 'Restaurant', l),
                    _amenity(context, Icons.support_agent, 'Concierge', l),
                  ],
                ),
              ),
            ),
            // Policies preview
            Padding(
              padding: EdgeInsets.all(isWide ? 40 : 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: SectionCard(
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 18,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        p,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ),
            ),
            // Footer
            HotelFooter(),
          ],
        ),
      ),
    );
  }

  Widget _amenity(BuildContext context, IconData icon, String label, L10n l) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.labelLarge),
        ],
      ),
    );
  }

  void _openBooking(BuildContext context, RoomType? type) {
    context.push(
      '/website/booking',
      extra: {'roomTypeId': type?.id, 'adults': type?.defaultAdults ?? 2},
    );
  }
}

class HotelFooter extends StatelessWidget {
  const HotelFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final store = context.watch<HotelStore>();
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.onSurface.withOpacity(0.04),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Wrap(
          spacing: 28,
          runSpacing: 16,
          children: [
            SizedBox(
              width: 280,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.appName, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    l.isArabic ? store.hotel.addressAr : store.hotel.address,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            _col(context, l.contact, [
              store.hotel.phone,
              store.hotel.email,
              'WhatsApp: +${store.hotel.whatsapp}',
            ]),
            _col(context, l.policies, [
              '${l.checkInDate}: ${store.hotel.checkInTime}',
              '${l.checkOutDate}: ${store.hotel.checkOutTime}',
              l.isArabic
                  ? 'إلغاء مجاني حتى 48 ساعة'
                  : 'Free cancellation up to 48h',
            ]),
          ],
        ),
      ),
    );
  }

  Widget _col(BuildContext context, String title, List<String> items) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ...items.map(
            (i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                i,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RoomTypeCard extends StatelessWidget {
  final RoomType type;
  const RoomTypeCard({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/website/room/${type.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RoomImage(palette: type.palette, icon: type.icon, height: 150),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.isArabic ? type.nameAr : type.name,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${type.bedConfig} • ${type.maxOccupancy} ${l.isArabic ? "نزيل" : "guests"} • ${type.sizeSqm}m²',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: type.amenities
                          .take(3)
                          .map(
                            (a) => Chip(
                              label: Text(a),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          )
                          .toList(),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: DefaultTextStyle.of(context).style,
                              children: [
                                TextSpan(
                                  text: Fmt.moneyShort(type.basePrice),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                TextSpan(
                                  text: ' ${l.perNight}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        FilledButton(
                          onPressed: () =>
                              context.push('/website/room/${type.id}'),
                          child: Text(l.bookNow),
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

// ============================================================
//  ROOMS PAGE
// ============================================================
class RoomsPage extends StatelessWidget {
  const RoomsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final store = context.watch<HotelStore>();
    final theme = Theme.of(context);
    final isWide = context.isDesktop;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 32 : 18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.rooms, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              l.isArabic
                  ? 'تصفّح كل أنواع الغرف واختبر التجربة'
                  : 'Browse all room types and find your stay',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 18),
            BookingSearchBar(onSearch: () => context.push('/website/booking')),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isWide ? 3 : (context.isTablet ? 2 : 1),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isWide ? 0.82 : 0.9,
              children: store.roomTypes
                  .map((t) => RoomTypeCard(type: t))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  GALLERY PAGE
// ============================================================
class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final store = context.watch<HotelStore>();
    final theme = Theme.of(context);
    final isWide = context.isDesktop;
    final palettes = store.roomTypes.map((t) => t.palette).toList();
    final labels = [
      l.isArabic ? 'الواجهة البحرية' : 'Seaside façade',
      l.isArabic ? 'مسبح السطح' : 'Rooftop pool',
      l.isArabic ? 'المطعم' : 'Restaurant',
      l.isArabic ? 'منطقة الاستقبال' : 'Reception lobby',
      l.isArabic ? 'الجناح' : 'Grand suite',
      l.isArabic ? 'غرفة ديلوكس' : 'Deluxe room',
    ];
    final icons = [
      Icons.waves,
      Icons.pool,
      Icons.restaurant,
      Icons.support_agent,
      Icons.apartment,
      Icons.king_bed_outlined,
    ];
    final colors =
        palettes +
        [
          [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
          [const Color(0xFF6A1B9A), const Color(0xFFAB47BC)],
        ];
    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 32 : 18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.gallery, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 18),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isWide ? 3 : 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.2,
              children: List.generate(6, (i) {
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: RoomImage(
                    palette: colors[i % colors.length],
                    icon: icons[i % icons.length],
                    height: double.infinity,
                    label: labels[i],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  CONTACT PAGE
// ============================================================
class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final store = context.watch<HotelStore>();
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.contact, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(
                children: [
                  _contactRow(
                    context,
                    Icons.location_on,
                    l.isArabic ? store.hotel.addressAr : store.hotel.address,
                  ),
                  _contactRow(context, Icons.phone, store.hotel.phone),
                  _contactRow(context, Icons.email, store.hotel.email),
                  _contactRow(
                    context,
                    Icons.chat,
                    'WhatsApp +${store.hotel.whatsapp}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: l.checkInDate,
              child: Text(store.hotel.checkInTime),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: l.checkOutDate,
              child: Text(store.hotel.checkOutTime),
            ),
            const SizedBox(height: 24),
            const HotelFooter(),
          ],
        ),
      ),
    );
  }

  Widget _contactRow(BuildContext context, IconData icon, String text) {
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

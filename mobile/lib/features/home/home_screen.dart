import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../core/config.dart';
import '../../core/models.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';

/// Home screen — homepage with all sections rendered from /api/public/home.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeData? _data;
  String? _error;
  bool _loading = true;

  // Quick booking state
  DateTime? _checkIn;
  DateTime? _checkOut;
  int _adults = 2;
  int _children = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _checkIn = DateTime(now.year, now.month, now.day + 1);
    _checkOut = DateTime(now.year, now.month, now.day + 3);
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = context.read<ApiClient>();
      final json = await api.get('/api/public/home') as Map<String, dynamic>;
      setState(() { _data = HomeData.fromJson(json); _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _pickDate({required bool isCheckIn}) async {
    final now = DateTime.now();
    final initial = isCheckIn ? (_checkIn ?? DateTime(now.year, now.month, now.day + 1)) : (_checkOut ?? DateTime(now.year, now.month, now.day + 3));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: isCheckIn ? DateTime(now.year, now.month, now.day) : DateTime(now.year, now.month, now.day + 1),
      lastDate: DateTime(now.year + 2),
      helpText: isCheckIn ? 'تاريخ الوصول' : 'تاريخ المغادرة',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppTheme.primary),
      ), child: child!),
    );
    if (picked == null) return;
    setState(() {
      if (isCheckIn) {
        _checkIn = picked;
        if (_checkOut == null || _checkOut!.isBefore(picked) || _checkOut == picked) {
          _checkOut = picked.add(const Duration(days: 1));
        }
      } else {
        if (_checkIn != null && (picked.isBefore(_checkIn!) || picked == _checkIn)) {
          _checkOut = _checkIn!.add(const Duration(days: 1));
        } else {
          _checkOut = picked;
        }
      }
    });
  }

  void _searchQuick() {
    if (_checkIn == null || _checkOut == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار التواريخ')));
      return;
    }
    Navigator.of(context).pushNamed('/rooms', arguments: <String, dynamic>{
      'checkIn': _fmtIso(_checkIn!),
      'checkOut': _fmtIso(_checkOut!),
      'adults': _adults,
      'children': _children,
    });
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر فتح الرابط')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      floatingActionButton: _data?.settings.whatsapp != null ? FloatingActionButton(
        onPressed: () => _openUrl('https://wa.me/${_data!.settings.whatsapp!.replaceAll(RegExp(r'[^0-9]'), '')}?text=${Uri.encodeQueryComponent('مرحبًا ${_data!.settings.hotelNameAr ?? ''}')}'),
        backgroundColor: const Color(0xFF25D366),
        mini: true,
        tooltip: 'واتساب',
        child: const Icon(Icons.chat_outlined),
      ) : null,
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView(message: 'جارٍ تحميل الفندق');
    if (_error != null) return ErrorView(message: 'تعذّر تحميل البيانات', onRetry: _load);
    if (_data == null) return const EmptyView(message: 'لا توجد بيانات');

    final sections = _data!.sections.where((s) => s.visible).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final s = _data!.settings;
    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          // Hero — always render first (whether or not section exists)
          if (sections.any((e) => e.key == 'hero'))
            _heroSliver(sections.firstWhere((e) => e.key == 'hero'), s)
          else
            _defaultHeroSliver(s),
          // Body sections
          SliverList(delegate: SliverChildListDelegate(_buildSections(sections, s))),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }

  SliverToBoxAdapter _heroSliver(ContentSection section, HotelSettings s) {
    final cfg = section.config;
    final image = cfg['image'] as String?;
    final title = (cfg['title_ar'] as String?) ?? s.hotelNameAr ?? 'فندق قلب القاهرة';
    final subtitle = (cfg['subtitle_ar'] as String?) ?? s.values['hotel.description_ar'] ?? '';
    final cta = (cfg['cta_ar'] as String?) ?? 'احجز الآن';
    return SliverToBoxAdapter(
      child: Stack(
        children: [
          SizedBox(
            height: 360,
            width: double.infinity,
            child: image != null
              ? Image.network(image, fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(color: AppTheme.primary.withValues(alpha: 0.3)))
              : Container(color: AppTheme.primary),
          ),
          Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withValues(alpha: 0.2), Colors.black.withValues(alpha: 0.65)])))),
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1.2)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 14, height: 1.4)),
                ],
                const SizedBox(height: 16),
                Row(children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed('/rooms'),
                    icon: const Icon(Icons.search, size: 18),
                    label: Text(cta),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _openUrl('tel:${s.phone ?? ''}'),
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('اتصل'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white70), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                  ),
                ]),
              ]),
            ),
          ),
          // Floating brand badge
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16, right: 16,
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(20)),
                child: Row(children: const [
                  Icon(Icons.apartment, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('Cairo Heart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                ]),
              ),
              const Spacer(),
              if (s.phone != null)
                InkWell(
                  onTap: () => _openUrl('tel:${s.phone}'),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                    child: const Icon(Icons.phone, color: Colors.white, size: 16),
                  ),
                ),
            ]),
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _defaultHeroSliver(HotelSettings s) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 24, left: 20, right: 20, bottom: 24),
        color: AppTheme.primary,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.hotelNameAr ?? 'فندق قلب القاهرة', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(s.values['hotel.description_ar'] ?? '', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed('/rooms'),
            icon: const Icon(Icons.search),
            label: const Text('احجز الآن'),
          ),
        ]),
      ),
    );
  }

  List<Widget> _buildSections(List<ContentSection> sections, HotelSettings s) {
    final widgets = <Widget>[];
    for (final sec in sections) {
      if (sec.key == 'hero') continue; // already rendered
      switch (sec.key) {
        case 'quick_booking':
          widgets.add(_quickBookingCard());
          break;
        case 'featured_rooms':
          widgets.add(_featuredRoomsSection(sec));
          break;
        case 'why_hotel':
          widgets.add(_whyHotelSection(sec));
          break;
        case 'offers':
          widgets.add(_offersSection(sec));
          break;
        case 'services':
          widgets.add(_servicesSection(sec));
          break;
        case 'gallery':
          widgets.add(_gallerySection(sec));
          break;
        case 'location':
          widgets.add(_locationSection(sec, s));
          break;
        case 'reviews':
          widgets.add(_reviewsSection(sec));
          break;
        case 'contact':
          widgets.add(_contactSection(sec, s));
          break;
        default:
          break;
      }
    }
    return widgets;
  }

  Widget _sectionWrap({required Widget child, double vertical = 16, bool horizontal = true}) => Padding(
    padding: EdgeInsets.fromLTRB(horizontal ? 16 : 0, vertical, horizontal ? 16 : 0, vertical),
    child: child,
  );

  // ── Quick booking ──
  Widget _quickBookingCard() {
    return _sectionWrap(
      vertical: 16,
      horizontal: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.event_available, color: AppTheme.primary, size: 20),
            SizedBox(width: 8),
            Text('حجز سريع', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          ]),
          const SizedBox(height: 4),
          const Text('اختر تواريخك وعدد الضيوف للبحث عن التوفر', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _dateField('الوصول', _checkIn, () => _pickDate(isCheckIn: true))),
            const SizedBox(width: 8),
            Expanded(child: _dateField('المغادرة', _checkOut, () => _pickDate(isCheckIn: false))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _stepper('بالغون', _adults, 1, 12, (v) => setState(() => _adults = v))),
            const SizedBox(width: 8),
            Expanded(child: _stepper('أطفال', _children, 0, 10, (v) => setState(() => _children = v))),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _searchQuick,
              icon: const Icon(Icons.search),
              label: const Text('ابحث عن غرف'),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _dateField(String label, DateTime? date, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        const SizedBox(height: 2),
        Row(children: [
          const Icon(Icons.event_outlined, size: 14, color: AppTheme.primary),
          const SizedBox(width: 4),
          Expanded(child: Text(
            date != null ? _fmtArDate(date) : 'اختر',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: date != null ? AppTheme.textPrimary : AppTheme.textSecondary),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          )),
        ]),
      ]),
    ),
  );

  Widget _stepper(String label, int value, int min, int max, ValueChanged<int> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary))),
        IconButton(onPressed: value > min ? () => onChanged(value - 1) : null, icon: const Icon(Icons.remove, size: 18), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
        Text(value.toString(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        IconButton(onPressed: value < max ? () => onChanged(value + 1) : null, icon: const Icon(Icons.add, size: 18), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
      ]),
    );
  }

  // ── Featured rooms ──
  Widget _featuredRoomsSection(ContentSection sec) {
    final title = (sec.config['title_ar'] as String?) ?? sec.titleAr;
    if (_data!.roomTypes.isEmpty) return const SizedBox.shrink();
    return _sectionWrap(
      vertical: 24,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionTitle(title: title, subtitle: 'اختر غرفتك المثالية', actionLabel: 'الكل', onAction: () => Navigator.of(context).pushNamed('/rooms')),
        const SizedBox(height: 12),
        SizedBox(
          height: 280,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _data!.roomTypes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _FeaturedRoomCard(roomType: _data!.roomTypes[i]),
          ),
        ),
      ]),
    );
  }

  // ── Why hotel ──
  Widget _whyHotelSection(ContentSection sec) {
    final title = (sec.config['title_ar'] as String?) ?? sec.titleAr;
    final features = (sec.config['features'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    if (features.isEmpty) return const SizedBox.shrink();
    return _sectionWrap(
      vertical: 24,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, c) {
          final cols = c.maxWidth > 720 ? 2 : 1;
          return GridView.count(
            crossAxisCount: cols,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: cols == 1 ? 4.0 : 2.2,
            children: features.asMap().entries.map((e) => _FeatureCard(text: e.value['ar'] as String? ?? '', index: e.key)).toList(),
          );
        }),
      ]),
    );
  }

  // ── Offers ──
  Widget _offersSection(ContentSection sec) {
    if (_data!.offers.isEmpty) return const SizedBox.shrink();
    final title = (sec.config['title_ar'] as String?) ?? sec.titleAr;
    return _sectionWrap(
      vertical: 24,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionTitle(title: title, subtitle: 'وفّر أكثر مع عروضنا الحصرية'),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _data!.offers.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _OfferCard(offer: _data!.offers[i]),
          ),
        ),
      ]),
    );
  }

  // ── Services ──
  Widget _servicesSection(ContentSection sec) {
    if (_data!.services.isEmpty) return const SizedBox.shrink();
    final title = (sec.config['title_ar'] as String?) ?? sec.titleAr;
    return _sectionWrap(
      vertical: 24,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionTitle(title: title, subtitle: 'خدمات ترفيهية متكاملة', actionLabel: 'الكل', onAction: () => Navigator.of(context).pushNamed('/services')),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, c) {
          final cols = c.maxWidth > 720 ? 4 : (c.maxWidth > 480 ? 3 : 2);
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: _data!.services.length,
            itemBuilder: (context, i) => _HomeServiceCard(service: _data!.services[i]),
          );
        }),
      ]),
    );
  }

  // ── Gallery ──
  Widget _gallerySection(ContentSection sec) {
    if (_data!.gallery.isEmpty) return const SizedBox.shrink();
    final title = (sec.config['title_ar'] as String?) ?? sec.titleAr;
    return _sectionWrap(
      vertical: 24,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, c) {
          final cols = c.maxWidth > 720 ? 3 : 2;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            itemCount: _data!.gallery.length,
            itemBuilder: (context, i) => ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: HotelNetworkImage(url: _data!.gallery[i].url, radius: BorderRadius.zero, aspectRatio: 1.0),
            ),
          );
        }),
      ]),
    );
  }

  // ── Location ──
  Widget _locationSection(ContentSection sec, HotelSettings s) {
    final title = (sec.config['title_ar'] as String?) ?? sec.titleAr;
    final maps = s.values['hotel.maps_url'] ?? 'https://maps.google.com/?q=${Uri.encodeComponent(s.addressAr ?? 'Cairo Heart Hotel Aden')}';
    return _sectionWrap(
      vertical: 24,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openUrl(maps),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                height: 140,
                color: AppTheme.background,
                child: Stack(children: [
                  Image.network(
                    'https://api.mapbox.com/styles/v1/mapbox/streets-v11/static/45.0337,12.7738,12,0/600x200@2x?access_token=',
                    fit: BoxFit.cover, width: double.infinity, height: 140,
                    errorBuilder: (_, _, _) => Container(
                      color: AppTheme.background,
                      child: const Center(child: Icon(Icons.map, size: 40, color: AppTheme.primary)),
                    ),
                  ),
                  Center(child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(20)),
                    child: const Icon(Icons.location_on, color: Colors.white, size: 22),
                  )),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.location_on_outlined, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.addressAr ?? 'عدن - شارع الملكة أروى', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    const SizedBox(height: 2),
                    const Text('اضغط لفتح خرائط جوجل', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ])),
                  const Icon(Icons.chevron_left, color: AppTheme.primary),
                ]),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── Reviews ──
  Widget _reviewsSection(ContentSection sec) {
    if (_data!.reviews.isEmpty) return const SizedBox.shrink();
    final title = (sec.config['title_ar'] as String?) ?? sec.titleAr;
    return _sectionWrap(
      vertical: 24,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _data!.reviews.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _ReviewCard(review: _data!.reviews[i]),
          ),
        ),
      ]),
    );
  }

  // ── Contact ──
  Widget _contactSection(ContentSection sec, HotelSettings s) {
    final title = (sec.config['title_ar'] as String?) ?? sec.titleAr;
    final whatsapp = (s.whatsapp ?? kDefaultWhatsapp).replaceAll(RegExp(r'[^0-9]'), '');
    return _sectionWrap(
      vertical: 24,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _openUrl('https://wa.me/$whatsapp?text=${Uri.encodeQueryComponent('مرحبًا، أرغب بالاستفسار عن الخدمات')}'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
              icon: const Icon(Icons.chat_outlined),
              label: const Text('واتساب'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: s.phone != null && s.phone!.isNotEmpty ? () => _openUrl('tel:${s.phone}') : null,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.white),
              icon: const Icon(Icons.phone),
              label: const Text('اتصال'),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed('/contact'),
            icon: const Icon(Icons.mail_outline),
            label: const Text('صفحة التواصل الكاملة'),
          ),
        ),
      ]),
    );
  }
}

// ── Cards ──
class _FeaturedRoomCard extends StatelessWidget {
  final RoomType roomType;
  const _FeaturedRoomCard({required this.roomType});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).pushNamed('/room', arguments: roomType.id),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            HotelNetworkImage(url: roomType.imageUrl, aspectRatio: 1.4, radius: BorderRadius.zero),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(roomType.nameAr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.people_outlined, size: 12, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text('${roomType.capacity}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  const SizedBox(width: 8),
                  Icon(Icons.bed_outlined, size: 12, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(child: Text(roomType.beds, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Text(roomType.basePrice.toStringAsFixed(0), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                  const SizedBox(width: 4),
                  Text('$kCurrencySymbol/ليلة', style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String text;
  final int index;
  const _FeatureCard({required this.text, required this.index});

  static const _icons = [Icons.location_on, Icons.hotel, Icons.support_agent, Icons.attach_money, Icons.local_dining, Icons.wifi];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(_icons[index % _icons.length], color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary, height: 1.3))),
        ]),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final Offer offer;
  const _OfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    final discount = offer.discountType == 'percentage'
      ? '${offer.discountValue.toStringAsFixed(0)}% خصم'
      : '${offer.discountValue.toStringAsFixed(0)} $kCurrencySymbol خصم';
    return SizedBox(
      width: 280,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).pushNamed('/rooms'),
          child: Stack(children: [
            if (offer.imageUrl != null) Positioned.fill(
              child: Image.network(offer.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(color: AppTheme.primary)),
            ),
            Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)])))),
            Positioned(
              top: 12, right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(20)),
                child: Text(discount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
              ),
            ),
            Positioned(
              left: 12, right: 12, bottom: 12,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(offer.nameAr, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(offer.descriptionAr, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _HomeServiceCard extends StatelessWidget {
  final Service service;
  const _HomeServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed('/services'),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          HotelNetworkImage(url: service.imageUrl, aspectRatio: 1.1, radius: BorderRadius.zero),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(service.nameAr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(service.price > 0 ? '${service.price.toStringAsFixed(0)} $kCurrencySymbol' : 'مجاني', style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              ...List.generate(5, (i) => Icon(i < review.rating ? Icons.star : Icons.star_border, color: const Color(0xFFFFB300), size: 16)),
              const Spacer(),
              Text(review.guestName, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
            const SizedBox(height: 8),
            Text(review.bodyAr, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, height: 1.4), maxLines: 5, overflow: TextOverflow.ellipsis),
            const Spacer(),
            Text(_fmtArDate(review.createdAt), style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
          ]),
        ),
      ),
    );
  }
}

String _fmtIso(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '$y-$m-$dd';
}
String _fmtArDate(DateTime d) {
  const months = ['يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

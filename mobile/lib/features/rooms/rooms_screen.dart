import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/config.dart';
import '../../core/models.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';

/// Rooms screen — browse all rooms, or search by dates and see live pricing.
class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  // Search params
  DateTime? _checkIn;
  DateTime? _checkOut;
  int _adults = 2;
  int _children = 0;

  // Browse list (no dates)
  List<RoomType>? _allRooms;
  String? _browseError;

  // Search results
  List<AvailabilityResult>? _results;
  bool _loading = false;
  bool _searched = false;
  String? _error;
  bool _searchBarExpanded = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && _checkIn == null) {
      final ci = args['checkIn'];
      final co = args['checkOut'];
      if (ci is String && co is String) {
        _checkIn = DateTime.tryParse(ci);
        _checkOut = DateTime.tryParse(co);
        final a = args['adults'];
        final c = args['children'];
        if (a is num) _adults = a.toInt();
        if (c is num) _children = c.toInt();
        _searchBarExpanded = false;
        // Trigger search after first build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _search();
        });
      }
    } else if (_allRooms == null && _browseError == null) {
      // Browse mode — load all room types
      _loadBrowse();
    }
  }

  Future<void> _loadBrowse() async {
    try {
      final api = context.read<ApiClient>();
      final res = await api.get('/api/public/room-types');
      final list = res is List ? res : const [];
      setState(() { _allRooms = list.map((e) => RoomType.fromJson(e as Map<String, dynamic>)).toList(); });
    } catch (e) {
      setState(() { _browseError = e.toString(); });
    }
  }

  Future<void> _pickDate({required bool isCheckIn}) async {
    final now = DateTime.now();
    final initial = isCheckIn ? (_checkIn ?? DateTime(now.year, now.month, now.day + 1)) : (_checkOut ?? DateTime(now.year, now.month, now.day + 3));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: isCheckIn ? DateTime(now.year, now.month, now.day) : (DateTime(now.year, now.month, now.day + 1)),
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

  Future<void> _search() async {
    if (_checkIn == null || _checkOut == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار التواريخ')));
      return;
    }
    setState(() { _loading = true; _error = null; _searched = true; });
    try {
      final api = context.read<ApiClient>();
      final res = await api.post('/api/availability/search', body: {
        'checkIn': _fmtIso(_checkIn!),
        'checkOut': _fmtIso(_checkOut!),
        'adults': _adults,
        'children': _children,
      }) as Map<String, dynamic>;
      final list = res['results'] as List? ?? const [];
      setState(() { _results = list.map((e) => AvailabilityResult.fromJson(e as Map<String, dynamic>)).toList(); });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  void _goToBooking(AvailabilityResult av) {
    final args = <String, dynamic>{
      'roomType': av.roomType,
      'checkIn': _fmtIso(_checkIn!),
      'checkOut': _fmtIso(_checkOut!),
      'adults': _adults,
      'children': _children,
      'nights': av.nights,
      'pricePerNight': av.pricePerNight,
      'total': av.total,
      'currency': av.currency,
      'appliedOffer': av.appliedOffer,
    };
    Navigator.of(context).pushNamed('/booking', arguments: args);
  }

  void _openRoomDetail(RoomType rt) {
    Navigator.of(context).pushNamed('/room', arguments: rt.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الغرف'),
        actions: [
          IconButton(
            icon: Icon(_searchBarExpanded ? Icons.expand_less : Icons.expand_more),
            onPressed: () => setState(() => _searchBarExpanded = !_searchBarExpanded),
            tooltip: 'إظهار/إخفاء البحث',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_searchBarExpanded) _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: _dateField('الوصول', _checkIn, () => _pickDate(isCheckIn: true))),
          const SizedBox(width: 8),
          Expanded(child: _dateField('المغادرة', _checkOut, () => _pickDate(isCheckIn: false))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _stepper('بالغون', _adults, 1, 12, (v) => setState(() => _adults = v))),
          const SizedBox(width: 8),
          Expanded(child: _stepper('أطفال', _children, 0, 10, (v) => setState(() => _children = v))),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _search,
            icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.search),
            label: Text(_loading ? 'جارٍ البحث...' : 'ابحث'),
          ),
        ),
      ]),
    );
  }

  Widget _buildBody() {
    if (_searched) {
      // Search results mode
      if (_loading) return const LoadingView(message: 'جارٍ البحث عن الغرف المتاحة');
      if (_error != null) return ErrorView(message: 'تعذّر إجراء البحث', onRetry: _search);
      if (_results == null || _results!.isEmpty) {
        return EmptyView(
          message: 'لا توجد غرف متاحة لهذه التواريخ',
          icon: Icons.search_off,
          actionLabel: 'تصفّح جميع الغرف',
          onAction: () => setState(() { _searched = false; _results = null; }),
        );
      }
      return RefreshIndicator(
        onRefresh: _search,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: _results!.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) return _searchSummaryHeader();
            return _AvailabilityCard(
              result: _results![i - 1],
              onBook: _goToBooking,
              onOpenDetail: (av) => _openRoomDetail(av.roomType),
            );
          },
        ),
      );
    }
    // Browse mode
    if (_allRooms == null && _browseError == null) {
      return const LoadingView(message: 'جارٍ تحميل الغرف');
    }
    if (_browseError != null) {
      return ErrorView(message: 'تعذّر تحميل الغرف', onRetry: _loadBrowse);
    }
    if (_allRooms!.isEmpty) {
      return const EmptyView(message: 'لا توجد غرف حاليًا', icon: Icons.bed_outlined);
    }
    return RefreshIndicator(
      onRefresh: _loadBrowse,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: _allRooms!.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) return _browseHeader();
          final rt = _allRooms![i - 1];
          return _BrowseCard(roomType: rt, onTap: () => _openRoomDetail(rt));
        },
      ),
    );
  }

  Widget _searchSummaryHeader() {
    final nights = _results!.isNotEmpty ? _results!.first.nights : 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.check_circle, color: AppTheme.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(
            '${_results!.length} ${_pluralize(_results!.length, 'غرفة متاحة', 'غرف متاحة')} • $nights ${nights == 1 ? 'ليلة' : 'ليالٍ'}',
            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 13),
          )),
          Text('${_fmtArDate(_checkIn!)} → ${_fmtArDate(_checkOut!)}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _browseHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('جميع الغرف', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        Text('اختر تواريخك أعلاه للبحث عن التوفر والأسعار مباشرة.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ]),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary))),
        IconButton(onPressed: value > min ? () => onChanged(value - 1) : null, icon: const Icon(Icons.remove, size: 18), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
        Text(value.toString(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        IconButton(onPressed: value < max ? () => onChanged(value + 1) : null, icon: const Icon(Icons.add, size: 18), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
      ]),
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  final AvailabilityResult result;
  final void Function(AvailabilityResult) onBook;
  final void Function(AvailabilityResult) onOpenDetail;
  const _AvailabilityCard({required this.result, required this.onBook, required this.onOpenDetail});

  @override
  Widget build(BuildContext context) {
    final rt = result.roomType;
    final available = result.availableRooms > 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onOpenDetail(result),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          HotelNetworkImage(url: rt.imageUrl, aspectRatio: 1.7, radius: BorderRadius.zero),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text(rt.nameAr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary))),
                if (!available) Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: const Text('غير متاحة', style: TextStyle(color: AppTheme.danger, fontSize: 10, fontWeight: FontWeight.w700)),
                ) else if (result.availableRooms <= 2) Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text('${result.availableRooms} متبقّية', style: const TextStyle(color: AppTheme.warning, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.people_outlined, size: 13, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text('${rt.capacity}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                const SizedBox(width: 10),
                Icon(Icons.bed_outlined, size: 13, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Expanded(child: Text(rt.beds, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (rt.size != null) ...[
                  const SizedBox(width: 10),
                  Icon(Icons.square_foot, size: 13, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text('${rt.size}م²', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ]),
              const SizedBox(height: 8),
              if (rt.amenities.isNotEmpty) Wrap(spacing: 4, runSpacing: 4, children: rt.amenities.take(5).map((a) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(6)),
                child: Text(_amenityLabel(a), style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
              )).toList()),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(10)),
                child: Column(children: [
                  Row(children: [
                    Text('السعر/ليلة', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    const Spacer(),
                    Text(_fmtMoney(result.pricePerNight, result.currency), style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text('${result.nights} ${result.nights == 1 ? 'ليلة' : 'ليالٍ'}', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    const Spacer(),
                    Text(_fmtMoney(result.subtotal, result.currency), style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                  ]),
                  if (result.discount > 0) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      Text('الخصم', style: TextStyle(fontSize: 12, color: AppTheme.success)),
                      const Spacer(),
                      Text('- ${_fmtMoney(result.discount, result.currency)}', style: const TextStyle(fontSize: 13, color: AppTheme.success, fontWeight: FontWeight.w700)),
                    ]),
                  ],
                  const Divider(height: 10),
                  Row(children: [
                    const Text('الإجمالي', style: TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text(_fmtMoney(result.total, result.currency), style: const TextStyle(fontSize: 16, color: AppTheme.primary, fontWeight: FontWeight.w800)),
                  ]),
                ]),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: available ? () => onBook(result) : null,
                  icon: const Icon(Icons.book_online),
                  label: const Text('احجز الآن'),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _BrowseCard extends StatelessWidget {
  final RoomType roomType;
  final VoidCallback onTap;
  const _BrowseCard({required this.roomType, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rt = roomType;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          HotelNetworkImage(url: rt.imageUrl, aspectRatio: 1.7, radius: BorderRadius.zero),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text(rt.nameAr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text('من ${rt.basePrice.toStringAsFixed(0)} $kCurrencySymbol', style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.people_outlined, size: 13, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text('${rt.capacity} ضيوف', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                const SizedBox(width: 10),
                Icon(Icons.bed_outlined, size: 13, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(rt.beds, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                if (rt.size != null) ...[
                  const SizedBox(width: 10),
                  Icon(Icons.square_foot, size: 13, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text('${rt.size}م²', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ]),
              const SizedBox(height: 8),
              Text(rt.descriptionAr, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.info_outline, size: 13, color: AppTheme.primary),
                const SizedBox(width: 4),
                Expanded(child: Text('اضغط لعرض التفاصيل والأسعار', style: TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600))),
                const Icon(Icons.chevron_left, color: AppTheme.primary, size: 18),
              ]),
            ]),
          ),
        ]),
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
String _fmtMoney(double amount, String currency) {
  final v = amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
  return currency == 'YER' ? '$v $kCurrencySymbol' : '$v $currency';
}
String _pluralize(int n, String singular, String plural) => n == 1 ? singular : plural;
String _amenityLabel(String a) {
  const map = <String, String>{
    'wifi': 'واي فاي', 'ac': 'تكييف', 'tv': 'تلفاز', 'minibar': 'ميني بار',
    'breakfast': 'فطور', 'view': 'إطلالة', 'safe': 'خزنة', 'lounge': 'جلوس',
    'bathtub': 'حوض استحمام', 'crib': 'سرير أطفال',
  };
  return map[a.toLowerCase()] ?? a;
}

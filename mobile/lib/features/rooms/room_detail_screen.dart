import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/config.dart';
import '../../core/models.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';

/// Room detail page — shows full info + availability checker + booking CTA.
class RoomDetailScreen extends StatefulWidget {
  final String roomTypeId;
  const RoomDetailScreen({super.key, required this.roomTypeId});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  RoomType? _roomType;
  String? _error;
  bool _loading = true;

  DateTime? _checkIn;
  DateTime? _checkOut;
  int _adults = 2;
  int _children = 0;
  AvailabilityResult? _availability;
  bool _checking = false;
  String? _checkError;

  @override
  void initState() {
    super.initState();
    // Default dates: tomorrow + day after
    final now = DateTime.now();
    _checkIn = DateTime(now.year, now.month, now.day + 1);
    _checkOut = DateTime(now.year, now.month, now.day + 3);
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = context.read<ApiClient>();
      final res = await api.get('/api/public/room-types');
      final list = res is List ? res : const [];
      for (final e in list) {
        final rt = RoomType.fromJson(e as Map<String, dynamic>);
        if (rt.id == widget.roomTypeId) {
          setState(() { _roomType = rt; _loading = false; });
          return;
        }
      }
      setState(() { _error = 'لم يتم العثور على الغرفة'; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _pickDate({required bool isCheckIn}) async {
    final now = DateTime.now();
    final initial = isCheckIn ? (_checkIn ?? now) : (_checkOut ?? now.add(const Duration(days: 1)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
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
        if (_checkOut != null && (_checkOut!.isBefore(picked) || _checkOut == picked)) {
          _checkOut = picked.add(const Duration(days: 1));
        }
      } else {
        if (_checkIn != null && (picked.isBefore(_checkIn!) || picked == _checkIn)) {
          _checkOut = _checkIn!.add(const Duration(days: 1));
        } else {
          _checkOut = picked;
        }
      }
      _availability = null;
    });
  }

  Future<void> _checkAvailability() async {
    if (_checkIn == null || _checkOut == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار التواريخ')));
      return;
    }
    setState(() { _checking = true; _checkError = null; });
    try {
      final api = context.read<ApiClient>();
      final res = await api.post('/api/availability/search', body: {
        'checkIn': _fmtIso(_checkIn!),
        'checkOut': _fmtIso(_checkOut!),
        'adults': _adults,
        'children': _children,
        'roomTypeId': widget.roomTypeId,
      }) as Map<String, dynamic>;
      final results = res['results'] as List? ?? const [];
      if (results.isEmpty) {
        setState(() { _availability = null; _checkError = 'لا توجد غرف متاحة'; });
      } else {
        setState(() { _availability = AvailabilityResult.fromJson(results.first as Map<String, dynamic>); });
      }
    } catch (e) {
      setState(() { _checkError = e.toString(); });
    } finally {
      if (mounted) setState(() { _checking = false; });
    }
  }

  void _goToBooking() {
    final av = _availability;
    final rt = _roomType;
    if (rt == null) return;
    final args = <String, dynamic>{
      'roomType': rt,
      'checkIn': _fmtIso(_checkIn!),
      'checkOut': _fmtIso(_checkOut!),
      'adults': _adults,
      'children': _children,
      'nights': av?.nights ?? 1,
      'pricePerNight': av?.pricePerNight ?? rt.basePrice,
      'total': av?.total ?? rt.basePrice,
      'currency': av?.currency ?? rt.currency,
      'appliedOffer': av?.appliedOffer,
    };
    Navigator.of(context).pushNamed('/booking', arguments: args);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الغرفة'), leading: IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back))),
      body: _buildBody(),
      bottomNavigationBar: _roomType == null ? null : _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView(message: 'جارٍ تحميل تفاصيل الغرفة');
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    if (_roomType == null) return const EmptyView(message: 'الغرفة غير موجودة');

    final rt = _roomType!;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Hero image
        AspectRatio(aspectRatio: 1.3, child: HotelNetworkImage(url: rt.imageUrl, radius: BorderRadius.zero)),
        // Content
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Text(rt.nameAr, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(20)),
                child: Text('${rt.basePrice.toStringAsFixed(0)} $kCurrencySymbol / ليلة', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ]),
            const SizedBox(height: 8),
            // Quick stats
            Wrap(spacing: 16, runSpacing: 8, children: [
              _statChip(Icons.people_outlined, '${rt.capacity} ضيوف'),
              _statChip(Icons.bed_outlined, rt.beds),
              if (rt.size != null) _statChip(Icons.square_foot, '${rt.size} م²'),
            ]),
            const SizedBox(height: 16),
            const Text('الوصف', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            Text(rt.descriptionAr, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.6)),
            const SizedBox(height: 16),
            if (rt.amenities.isNotEmpty) ...[
              const Text('وسائل الراحة', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: rt.amenities.map((a) => Chip(
                label: Text(_amenityLabel(a)),
                avatar: Icon(_amenityIcon(a), size: 16, color: AppTheme.primary),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              )).toList()),
            ],
            const SizedBox(height: 24),
            // Availability checker
            _availabilityCard(),
          ]),
        ),
      ],
    );
  }

  Widget _availabilityCard() {
    return Card(
      color: AppTheme.background,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.event_available, color: AppTheme.primary, size: 20),
            SizedBox(width: 8),
            Text('تحقق من التوفر', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _dateField('الوصول', _checkIn, () => _pickDate(isCheckIn: true))),
            const SizedBox(width: 12),
            Expanded(child: _dateField('المغادرة', _checkOut, () => _pickDate(isCheckIn: false))),
          ]),
          const SizedBox(height: 12),
          _stepperRow('البالغون', _adults, 1, 12, (v) => setState(() { _adults = v; _availability = null; })),
          const SizedBox(height: 8),
          _stepperRow('الأطفال', _children, 0, 10, (v) => setState(() { _children = v; _availability = null; })),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _checking ? null : _checkAvailability,
              icon: _checking ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.search),
              label: Text(_checking ? 'جارٍ البحث...' : 'ابحث عن التوفر'),
            ),
          ),
          if (_checkError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
              child: Text(_checkError!, style: const TextStyle(color: AppTheme.danger, fontSize: 12)),
            ),
          ],
          if (_availability != null) ...[
            const SizedBox(height: 12),
            _availabilityResult(),
          ],
        ]),
      ),
    );
  }

  Widget _availabilityResult() {
    final av = _availability!;
    final isAvailable = av.availableRooms > 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAvailable ? AppTheme.success.withValues(alpha: 0.06) : AppTheme.danger.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isAvailable ? AppTheme.success.withValues(alpha: 0.3) : AppTheme.danger.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(isAvailable ? Icons.check_circle : Icons.cancel, color: isAvailable ? AppTheme.success : AppTheme.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(
            isAvailable ? '${av.availableRooms} ${av.availableRooms == 1 ? 'غرفة متاحة' : 'غرف متاحة'} من ${av.totalRooms}' : 'لا توجد غرف متاحة لهذه التواريخ',
            style: TextStyle(color: isAvailable ? AppTheme.success : AppTheme.danger, fontWeight: FontWeight.w700, fontSize: 13),
          )),
        ]),
        if (isAvailable) ...[
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          _priceRow('سعر الليلة', _fmtMoney(av.pricePerNight, av.currency)),
          _priceRow('عدد الليالي', '${av.nights} × ${_fmtMoney(av.pricePerNight, av.currency)}'),
          _priceRow('المجموع', _fmtMoney(av.subtotal, av.currency)),
          if (av.discount > 0) ...[
            _priceRow('الخصم', '- ${_fmtMoney(av.discount, av.currency)}'),
            if (av.appliedOffer?['nameAr'] != null) _priceRow('العرض المطبّق', av.appliedOffer!['nameAr'] as String),
          ],
          const Divider(height: 8),
          Row(children: [
            const Text('الإجمالي', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
            const Spacer(),
            Text(_fmtMoney(av.total, av.currency), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primary)),
          ]),
        ],
      ]),
    );
  }

  Widget _priceRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
      Text(value, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _dateField(String label, DateTime? date, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        const SizedBox(height: 2),
        Row(children: [
          const Icon(Icons.event_outlined, size: 16, color: AppTheme.primary),
          const SizedBox(width: 6),
          Expanded(child: Text(
            date != null ? _fmtArDate(date) : 'اختر التاريخ',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: date != null ? AppTheme.textPrimary : AppTheme.textSecondary),
          )),
        ]),
      ]),
    ),
  );

  Widget _stepperRow(String label, int value, int min, int max, ValueChanged<int> onChanged) {
    return Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary))),
      Row(children: [
        IconButton(onPressed: value > min ? () => onChanged(value - 1) : null, icon: const Icon(Icons.remove_circle_outline), color: AppTheme.primary),
        Text(value.toString(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        IconButton(onPressed: value < max ? () => onChanged(value + 1) : null, icon: const Icon(Icons.add_circle_outline), color: AppTheme.primary),
      ]),
    ]);
  }

  Widget _statChip(IconData icon, String label) => Row(children: [
    Icon(icon, size: 16, color: AppTheme.primary),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
  ]);

  Widget _buildBottomBar() {
    final av = _availability;
    final hasAv = av != null && av.availableRooms > 0;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.surface, border: Border(top: BorderSide(color: Colors.grey.shade200))),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(
              hasAv ? _fmtMoney(av.total, av.currency) : '${_roomType!.basePrice.toStringAsFixed(0)} $kCurrencySymbol / ليلة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primary),
            ),
            Text(
              hasAv ? '${av.nights} ${av.nights == 1 ? 'ليلة' : 'ليالٍ'}' : 'السعر الأساسي',
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ])),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _checkIn == null || _checkOut == null ? null : _goToBooking,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
            child: const Text('احجز هذه الغرفة'),
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

IconData _amenityIcon(String a) {
  switch (a.toLowerCase()) {
    case 'wifi': return Icons.wifi;
    case 'ac': return Icons.ac_unit;
    case 'tv': return Icons.tv;
    case 'minibar': return Icons.local_bar;
    case 'breakfast': return Icons.free_breakfast;
    case 'view': return Icons.visibility;
    case 'safe': return Icons.lock_outline;
    case 'lounge': return Icons.weekend_outlined;
    case 'bathtub': return Icons.bathtub_outlined;
    case 'crib': return Icons.child_care;
    default: return Icons.check_circle_outline;
  }
}
String _amenityLabel(String a) {
  const map = <String, String>{
    'wifi': 'واي فاي', 'ac': 'تكييف', 'tv': 'تلفاز', 'minibar': 'ميني بار',
    'breakfast': 'فطور', 'view': 'إطلالة', 'safe': 'خزنة', 'lounge': 'جلوس',
    'bathtub': 'حوض استحمام', 'crib': 'سرير أطفال',
  };
  return map[a.toLowerCase()] ?? a;
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hotel_platform/core/constants.dart';
import 'package:hotel_platform/core/utils/format.dart';
import 'package:hotel_platform/data/models.dart';
import 'package:hotel_platform/data/store.dart';
import 'package:hotel_platform/l10n/app_localizations.dart';
import 'package:hotel_platform/shared/widgets/common_widgets.dart';

/// Multi-step booking flow (PLAN §8, §10):
/// 1) Dates + occupancy  2) Room type selection  3) Guest details
/// 4) Payment method   5) Confirmation preview -> create reservation.
class BookingFlowScreen extends StatefulWidget {
  final String? roomTypeId;
  final DateTime? initialCheckIn;
  final DateTime? initialCheckOut;
  final int adults;
  const BookingFlowScreen({
    super.key,
    this.roomTypeId,
    this.initialCheckIn,
    this.initialCheckOut,
    this.adults = 2,
  });

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  late DateTime _checkIn;
  late DateTime _checkOut;
  int _adults = 2;
  int _children = 0;
  String? _roomTypeId;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  PaymentMethod _method = PaymentMethod.payAtHotel;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _checkIn =
        widget.initialCheckIn ??
        DateTime(n.year, n.month, n.day).add(const Duration(days: 1));
    _checkOut = widget.initialCheckOut ?? _checkIn.add(const Duration(days: 3));
    _adults = widget.adults;
    _roomTypeId = widget.roomTypeId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _next() => setState(() => _step++);
  void _prevReal() {
    if (_step > 0) setState(() => _step--);
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step > 0) {
              _prevReal();
            } else {
              context.pop();
            }
          },
        ),
        title: Text(l.bookNow),
      ),
      body: StepperBody(step: _step),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (_step > 0)
                OutlinedButton(onPressed: _prevReal, child: Text(l.back))
              else
                OutlinedButton(
                  onPressed: () => context.pop(),
                  child: Text(l.cancel),
                ),
              const Spacer(),
              FilledButton(
                onPressed: _onNext,
                child: Text(_step == 4 ? l.confirm : l.next),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onNext() {
    final l = L10n.of(context);
    if (_step == 0) {
      if (!_checkOut.isAfter(_checkIn)) {
        _toast(
          l.isArabic
              ? 'تاريخ المغادرة يجب أن يكون بعد الوصول'
              : 'Check-out must be after check-in',
        );
        return;
      }
      _next();
    } else if (_step == 1) {
      if (_roomTypeId == null) {
        _toast(l.selectRoomType);
        return;
      }
      final store = context.read<HotelStore>();
      final avail = store.availableCountForType(
        _roomTypeId!,
        _checkIn,
        _checkOut,
      );
      if (avail <= 0) {
        _toast(
          l.isArabic
              ? 'لا توجد غرف متاحة لهذه الفترة'
              : 'No rooms available for these dates',
        );
        return;
      }
      _next();
    } else if (_step == 2) {
      if (_nameCtrl.text.trim().isEmpty ||
          _emailCtrl.text.trim().isEmpty ||
          _phoneCtrl.text.trim().isEmpty) {
        _toast(
          l.isArabic
              ? 'يرجى إكمال بيانات النزيل'
              : 'Please complete guest details',
        );
        return;
      }
      _next();
    } else if (_step == 3) {
      _next();
    } else if (_step == 4) {
      _confirm();
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _confirm() {
    final store = context.read<HotelStore>();
    final guest = store.upsertGuest(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
    );
    final res = store.createReservation(
      guestId: guest.id,
      roomTypeId: _roomTypeId!,
      checkIn: _checkIn,
      checkOut: _checkOut,
      adults: _adults,
      children: _children,
      paymentMethod: _method,
      amountPaid: _method == PaymentMethod.payAtHotel ? 0 : 0,
    );
    context.replace('/booking/confirmation/${res.id}');
  }

  // ---- step body ----
  Widget StepperBody({required int step}) {
    switch (step) {
      case 0:
        return _DatesStep(
          checkIn: _checkIn,
          checkOut: _checkOut,
          adults: _adults,
          children: _children,
          onCheckIn: (d) => setState(() {
            _checkIn = d;
            if (!_checkOut.isAfter(_checkIn)) {
              _checkOut = _checkIn.add(const Duration(days: 1));
            }
          }),
          onCheckOut: (d) => setState(() => _checkOut = d),
          onAdults: (v) => setState(() => _adults = v),
          onChildren: (v) => setState(() => _children = v),
        );
      case 1:
        return _RoomTypeStep(
          selected: _roomTypeId,
          checkIn: _checkIn,
          checkOut: _checkOut,
          adults: _adults,
          onSelect: (id) => setState(() => _roomTypeId = id),
        );
      case 2:
        return _GuestStep(
          name: _nameCtrl,
          email: _emailCtrl,
          phone: _phoneCtrl,
        );
      case 3:
        return _PaymentStep(
          method: _method,
          onMethod: (m) => setState(() => _method = m),
        );
      case 4:
        return _ReviewStep(
          roomTypeId: _roomTypeId!,
          checkIn: _checkIn,
          checkOut: _checkOut,
          adults: _adults,
          children: _children,
          method: _method,
          name: _nameCtrl.text,
        );
      default:
        return const SizedBox();
    }
  }
}

// ============================================================
//  STEP 0 — DATES & OCCUPANCY
// ============================================================
class _DatesStep extends StatelessWidget {
  final DateTime checkIn;
  final DateTime checkOut;
  final int adults;
  final int children;
  final ValueChanged<DateTime> onCheckIn;
  final ValueChanged<DateTime> onCheckOut;
  final ValueChanged<int> onAdults;
  final ValueChanged<int> onChildren;
  const _DatesStep({
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    required this.onCheckIn,
    required this.onCheckOut,
    required this.onAdults,
    required this.onChildren,
  });

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepHeader(no: 1, title: l.checkInDate),
            const SizedBox(height: 8),
            _DateTile(label: l.checkInDate, value: checkIn, onPick: onCheckIn),
            const SizedBox(height: 10),
            _DateTile(
              label: l.checkOutDate,
              value: checkOut,
              onPick: onCheckOut,
            ),
            const SizedBox(height: 6),
            Text(
              '${Fmt.nights(checkIn, checkOut)} ${Fmt.nights(checkIn, checkOut) == 1 ? l.night : l.nights}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            _Stepper(
              label: l.adults,
              value: adults,
              min: 1,
              max: 6,
              onChanged: onAdults,
            ),
            const SizedBox(height: 12),
            _Stepper(
              label: l.children,
              value: children,
              min: 0,
              max: 4,
              onChanged: onChildren,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onPick;
  const _DateTile({
    required this.label,
    required this.value,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final p = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (p != null) onPick(p);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelSmall),
                  Text(
                    Fmt.date(value),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  const _Stepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.titleMedium),
        ),
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('$value', style: Theme.of(context).textTheme.titleLarge),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}

// ============================================================
//  STEP 1 — ROOM TYPE
// ============================================================
class _RoomTypeStep extends StatelessWidget {
  final String? selected;
  final DateTime checkIn;
  final DateTime checkOut;
  final int adults;
  final ValueChanged<String> onSelect;
  const _RoomTypeStep({
    required this.selected,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.onSelect,
  });

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
            _StepHeader(no: 2, title: l.selectRoomType),
            const SizedBox(height: 14),
            ...store.roomTypes.map((t) {
              final avail = store.availableCountForType(
                t.id,
                checkIn,
                checkOut,
              );
              final price = store.calculatePrice(t, checkIn, checkOut, adults);
              final selected = this.selected == t.id;
              return Card(
                child: ListTile(
                  onTap: avail > 0 ? () => onSelect(t.id) : null,
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: RoomImage(
                        palette: t.palette,
                        icon: t.icon,
                        height: 72,
                      ),
                    ),
                  ),
                  title: Text(
                    l.isArabic ? t.nameAr : t.name,
                    style: theme.textTheme.titleMedium,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${t.bedConfig} • ${t.maxOccupancy} ${l.isArabic ? "نزيل" : "guests"}',
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (avail > 0)
                              StatusChip(
                                label:
                                    '$avail ${l.isArabic ? "متاح" : "available"}',
                                color: const Color(0xFF2E7D32),
                              )
                            else
                              StatusChip(
                                label: l.isArabic ? 'غير متاح' : 'Unavailable',
                                color: const Color(0xFFC62828),
                              ),
                            const SizedBox(width: 8),
                            Text(
                              Fmt.money(price.total),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  trailing: selected
                      ? Icon(
                          Icons.check_circle,
                          color: theme.colorScheme.primary,
                          size: 30,
                        )
                      : const Icon(Icons.radio_button_unchecked),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  STEP 2 — GUEST
// ============================================================
class _GuestStep extends StatelessWidget {
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController phone;
  const _GuestStep({
    required this.name,
    required this.email,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepHeader(no: 3, title: l.guestDetails),
            const SizedBox(height: 14),
            TextField(
              controller: name,
              decoration: InputDecoration(
                labelText: l.fullName,
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: l.email,
                prefixIcon: const Icon(Icons.mail_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l.phone,
                prefixIcon: const Icon(Icons.phone),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  STEP 3 — PAYMENT
// ============================================================
class _PaymentStep extends StatelessWidget {
  final PaymentMethod method;
  final ValueChanged<PaymentMethod> onMethod;
  const _PaymentStep({required this.method, required this.onMethod});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepHeader(no: 4, title: l.paymentMethod),
            const SizedBox(height: 14),
            _MethodTile(
              icon: Icons.receipt_long_outlined,
              title: l.payAtHotel,
              subtitle: l.isArabic
                  ? 'ادفع عند الوصول للفندق'
                  : 'Pay at the hotel on arrival',
              selected: method == PaymentMethod.payAtHotel,
              onTap: () => onMethod(PaymentMethod.payAtHotel),
            ),
            _MethodTile(
              icon: Icons.credit_card,
              title: l.isArabic ? 'بطاقة ائتمان' : 'Credit card',
              subtitle: l.isArabic
                  ? 'تُحجز مباشرةً (محاكاة)'
                  : 'Charged immediately (simulated)',
              selected: method == PaymentMethod.creditCard,
              onTap: () => onMethod(PaymentMethod.creditCard),
            ),
            _MethodTile(
              icon: Icons.payments_outlined,
              title: l.isArabic ? 'نقداً' : 'Cash',
              subtitle: l.isArabic
                  ? 'ادفع نقداً عند الوصول'
                  : 'Pay cash on arrival',
              selected: method == PaymentMethod.cash,
              onTap: () => onMethod(PaymentMethod.cash),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _MethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: selected ? theme.colorScheme.primary.withOpacity(0.08) : null,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Text(subtitle),
        trailing: selected
            ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
            : const Icon(Icons.radio_button_unchecked),
      ),
    );
  }
}

// ============================================================
//  STEP 4 — REVIEW
// ============================================================
class _ReviewStep extends StatelessWidget {
  final String roomTypeId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int adults;
  final int children;
  final PaymentMethod method;
  final String name;
  const _ReviewStep({
    required this.roomTypeId,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    required this.method,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final store = context.watch<HotelStore>();
    final type = store.roomTypeById(roomTypeId)!;
    final price = store.calculatePrice(type, checkIn, checkOut, adults);
    final nights = Fmt.nights(checkIn, checkOut);
    String methodName() {
      switch (method) {
        case PaymentMethod.payAtHotel:
          return l.payAtHotel;
        case PaymentMethod.creditCard:
          return l.isArabic ? 'بطاقة ائتمان' : 'Credit card';
        case PaymentMethod.cash:
          return l.isArabic ? 'نقداً' : 'Cash';
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepHeader(
              no: 5,
              title: l.isArabic ? 'مراجعة وتأكيد' : 'Review & confirm',
            ),
            const SizedBox(height: 14),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row(
                    context,
                    l.isArabic ? 'الغرفة' : 'Room',
                    l.isArabic ? type.nameAr : type.name,
                  ),
                  _row(context, l.checkInDate, Fmt.date(checkIn)),
                  _row(context, l.checkOutDate, Fmt.date(checkOut)),
                  _row(
                    context,
                    l.isArabic ? 'المدة' : 'Duration',
                    '$nights ${nights == 1 ? l.night : l.nights}',
                  ),
                  _row(
                    context,
                    l.isArabic ? 'النزلاء' : 'Guests',
                    '$adults ${l.adults.toLowerCase()}' +
                        (children > 0
                            ? ' + $children ${l.children.toLowerCase()}'
                            : ''),
                  ),
                  _row(context, l.isArabic ? 'الاسم' : 'Name', name),
                  _row(context, l.paymentMethod, methodName()),
                  const Divider(height: 24),
                  _row(context, l.subtotal, Fmt.money(price.subtotal)),
                  _row(context, l.taxes, Fmt.money(price.tax)),
                  _row(context, l.total, Fmt.money(price.total), bold: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String k, String v, {bool bold = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.65),
              ),
            ),
          ),
          Text(
            v,
            style: bold
                ? theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  )
                : theme.textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final int no;
  final String title;
  const _StepHeader({required this.no, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$no',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(title, style: theme.textTheme.headlineSmall),
      ],
    );
  }
}

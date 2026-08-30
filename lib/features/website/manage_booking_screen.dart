import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hotel_platform/core/constants.dart';
import 'package:hotel_platform/core/utils/format.dart';
import 'package:hotel_platform/data/models.dart';
import 'package:hotel_platform/data/store.dart';
import 'package:hotel_platform/features/website/website_shell.dart';
import 'package:hotel_platform/l10n/app_localizations.dart';
import 'package:hotel_platform/shared/widgets/common_widgets.dart';

/// Website Manage-Booking (PLAN_WEBSITE §47–§51).
///
/// Guests retrieve their reservation using a booking reference + a
/// verification value (phone OR email). The booking reference alone is NEVER
/// enough (§47, line 1302: "Never allow access based only on a guessable
/// booking reference."). After lookup the guest can view the reservation,
/// modify it, or cancel it per policy.
class ManageBookingScreen extends StatefulWidget {
  final String? reservationId;
  const ManageBookingScreen({super.key, this.reservationId});

  @override
  State<ManageBookingScreen> createState() => _ManageBookingScreenState();
}

class _ManageBookingScreenState extends State<ManageBookingScreen> {
  final _refCtrl = TextEditingController();
  final _verCtrl = TextEditingController();
  String? _error;
  Reservation? _found;

  @override
  void dispose() {
    _refCtrl.dispose();
    _verCtrl.dispose();
    super.dispose();
  }

  void _lookup() {
    final store = context.read<HotelStore>();
    final l = L10n.of(context);
    final ref = _refCtrl.text.trim();
    final ver = _verCtrl.text.trim();
    if (ref.isEmpty || ver.isEmpty) {
      setState(
        () => _error = l.isArabic
            ? 'أدخل رقم الحجوز وقيمة التحقق (الهاتف أو البريد)'
            : 'Enter the booking reference and verification value (phone or email)',
      );
      return;
    }
    final res = store.lookupReservation(ref, ver);
    if (res == null) {
      setState(() {
        _error = l.isArabic
            ? 'لم يتم العثور على حجز مطابق. تحقق من البيانات.'
            : 'No matching booking found. Check your details.';
        _found = null;
      });
      return;
    }
    setState(() {
      _error = null;
      _found = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final theme = Theme.of(context);
    final store = context.watch<HotelStore>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.manageBooking, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              l.isArabic
                  ? 'استرجع حجزك باستخدام رقم الحجز وقيمة التحقق (الهاتف أو البريد)'
                  : 'Retrieve your booking using the reference and a verification value (phone or email)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 18),
            if (_found == null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _refCtrl,
                        decoration: InputDecoration(
                          labelText: l.reservationNo,
                          hintText: 'HTL-2026-000421',
                          prefixIcon: const Icon(Icons.receipt_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _verCtrl,
                        decoration: InputDecoration(
                          labelText: l.isArabic
                              ? 'قيمة التحقق (الهاتف أو البريد)'
                              : 'Verification (phone or email)',
                          prefixIcon: const Icon(Icons.verified_user_outlined),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _error!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: _lookup,
                          icon: const Icon(Icons.search),
                          label: Text(l.manageBooking),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Demo hint
              Card(
                color: theme.colorScheme.primary.withOpacity(0.06),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l.isArabic
                              ? 'للتجربة: استخدم HTL-2026-000421 + رقم هاتف النزيل'
                              : 'Demo: use HTL-2026-000421 + the guest\'s phone number',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.auto_awesome),
                        tooltip: l.isArabic ? 'ملء تلقائي' : 'Auto-fill demo',
                        onPressed: () {
                          setState(() {
                            _refCtrl.text = 'HTL-2026-000421';
                            _verCtrl.text = '+971 50 123 4567';
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              _ReservationDetail(res: _found!, store: store),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.home_outlined),
                    label: Text(
                      l.isArabic ? 'العودة للرئيسية' : 'Back to home',
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() {
                      _found = null;
                      _refCtrl.clear();
                      _verCtrl.clear();
                    }),
                    child: Text(
                      l.isArabic ? 'بحث عن حجز آخر' : 'Look up another',
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            const HotelFooter(),
          ],
        ),
      ),
    );
  }
}

class _ReservationDetail extends StatelessWidget {
  final Reservation res;
  final HotelStore store;
  const _ReservationDetail({required this.res, required this.store});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final theme = Theme.of(context);
    final guest = store.guestById(res.guestId);
    final type = store.roomTypeById(res.roomTypeId)!;
    final nights = Fmt.nights(res.checkIn, res.checkOut);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.isArabic
                        ? 'تم العثور على حجزك'
                        : 'Your booking was found',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                StatusChip(
                  label: res.status.label,
                  color: const Color(0xFF2E7D32),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _row(context, l.reservationNo, res.id, bold: true),
            const Divider(height: 24),
            _row(context, l.fullName, guest?.name ?? ''),
            _row(context, l.email, guest?.email ?? ''),
            _row(context, l.phone, guest?.phone ?? ''),
            const Divider(height: 24),
            _row(
              context,
              l.isArabic ? 'الغرفة' : 'Room type',
              l.isArabic ? type.nameAr : type.name,
            ),
            _row(context, l.checkInDate, Fmt.date(res.checkIn)),
            _row(context, l.checkOutDate, Fmt.date(res.checkOut)),
            _row(
              context,
              l.isArabic ? 'المدة' : 'Duration',
              '$nights ${nights == 1 ? l.night : l.nights}',
            ),
            _row(
              context,
              l.isArabic ? 'النزلاء' : 'Guests',
              '${res.adults} ${l.adults.toLowerCase()}${res.children > 0 ? " + ${res.children} ${l.children.toLowerCase()}" : ""}',
            ),
            const Divider(height: 24),
            _row(context, l.subtotal, Fmt.money(res.price.subtotal)),
            _row(context, l.taxes, Fmt.money(res.price.tax)),
            _row(context, l.total, Fmt.money(res.price.total), bold: true),
            _row(context, l.paymentMethod, _methodLabel(res.paymentMethod, l)),
          ],
        ),
      ),
    );
  }

  String _methodLabel(PaymentMethod m, L10n l) {
    switch (m) {
      case PaymentMethod.payAtHotel:
        return l.payAtHotel;
      case PaymentMethod.creditCard:
        return l.isArabic ? 'بطاقة ائتمان' : 'Credit card';
      case PaymentMethod.cash:
        return l.isArabic ? 'نقداً' : 'Cash';
    }
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
          Flexible(
            child: Text(
              v,
              textAlign: TextAlign.end,
              style: bold
                  ? theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    )
                  : theme.textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hotel_platform/core/constants.dart';
import 'package:hotel_platform/core/utils/format.dart';
import 'package:hotel_platform/data/models.dart';
import 'package:hotel_platform/data/store.dart';
import 'package:hotel_platform/l10n/app_localizations.dart';
import 'package:hotel_platform/shared/widgets/common_widgets.dart';

class ConfirmationScreen extends StatelessWidget {
  final String reservationId;
  const ConfirmationScreen({super.key, required this.reservationId});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final store = context.watch<HotelStore>();
    final theme = Theme.of(context);
    final res = store.reservationById(reservationId);
    if (res == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(icon: Icons.error_outline, message: l.noResults),
      );
    }
    final guest = store.guestById(res.guestId);
    final type = store.roomTypeById(res.roomTypeId)!;
    final nights = Fmt.nights(res.checkIn, res.checkOut);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          onPressed: () => context.go('/website'),
        ),
        title: Text(l.bookingConfirmed),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle,
                          color: Color(0xFF2E7D32), size: 56),
                    ),
                    const SizedBox(height: 12),
                    Text(l.bookingConfirmed, style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      l.isArabic
                          ? 'تم إنشاء حجزك بنجاح. أرسلنا التأكيد عبر WhatsApp.'
                          : 'Your reservation is confirmed. A confirmation has been sent via WhatsApp.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _row(context, l.reservationNo, res.id, bold: true),
                      const Divider(height: 24),
                      _row(context, l.fullName, guest?.name ?? ''),
                      _row(context, l.email, guest?.email ?? ''),
                      _row(context, l.phone, guest?.phone ?? ''),
                      const Divider(height: 24),
                      _row(context, l.isArabic ? 'الغرفة' : 'Room type',
                          l.isArabic ? type.nameAr : type.name),
                      _row(context, l.checkInDate, Fmt.date(res.checkIn)),
                      _row(context, l.checkOutDate, Fmt.date(res.checkOut)),
                      _row(context, l.isArabic ? 'المدة' : 'Duration',
                          '$nights ${nights == 1 ? l.night : l.nights}'),
                      _row(context, l.isArabic ? 'النزلاء' : 'Guests',
                          '${res.adults} ${l.adults.toLowerCase()}${res.children > 0 ? " + ${res.children} ${l.children.toLowerCase()}" : ""}'),
                      const Divider(height: 24),
                      _row(context, l.subtotal, Fmt.money(res.price.subtotal)),
                      _row(context, l.taxes, Fmt.money(res.price.tax)),
                      _row(context, l.total, Fmt.money(res.price.total), bold: true),
                      _row(context, l.paymentMethod, _methodLabel(res.paymentMethod, l)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/website'),
                      icon: const Icon(Icons.home_outlined),
                      label: Text(l.isArabic ? 'العودة للرئيسية' : 'Back to home'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => context.push('/website/booking'),
                      icon: const Icon(Icons.add),
                      label: Text(l.bookAnother),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // WhatsApp-style note (PLAN §11)
              Card(
                color: const Color(0xFFE8F5E9),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.chat, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l.isArabic
                              ? 'تم إرسال تأكيد الحجز عبر WhatsApp إلى ${guest?.phone ?? ""}'
                              : 'Booking confirmation sent via WhatsApp to ${guest?.phone ?? ""}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
            child: Text(k, style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.65),
            )),
          ),
          Flexible(
            child: Text(
              v,
              textAlign: TextAlign.end,
              style: bold
                  ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)
                  : theme.textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

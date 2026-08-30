import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hotel_platform/core/app_state.dart';
import 'package:hotel_platform/core/constants.dart';
import 'package:hotel_platform/core/utils/format.dart';
import 'package:hotel_platform/data/models.dart';
import 'package:hotel_platform/data/store.dart';
import 'package:hotel_platform/l10n/app_localizations.dart';
import 'package:hotel_platform/shared/widgets/common_widgets.dart';

class CheckoutRequestScreen extends StatelessWidget {
  const CheckoutRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final app = context.watch<AppState>();
    final store = context.watch<HotelStore>();
    final theme = Theme.of(context);
    final stay = store.currentStayForGuest(app.guestId!)!;
    final balance = store.outstandingBalance(stay.id);
    final pendingReqs = store
        .requestsForStay(stay.id)
        .where(
          (r) =>
              r.status != RequestStatus.completed &&
              r.status != RequestStatus.cancelled &&
              r.status != RequestStatus.rejected,
        )
        .length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l.checkoutRequest),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row(
                      context,
                      l.isArabic ? 'المغادرة' : 'Checkout',
                      Fmt.date(stay.checkOut),
                    ),
                    _row(
                      context,
                      l.outstandingBalance,
                      Fmt.money(balance),
                      color: balance > 0
                          ? const Color(0xFFEF6C00)
                          : const Color(0xFF2E7D32),
                    ),
                    _row(
                      context,
                      l.requests,
                      '$pendingReqs ${l.isArabic ? "معلّق" : "open"}',
                    ),
                    _row(
                      context,
                      l.isArabic ? 'الحالة' : 'Status',
                      stay.status == StayStatus.checkoutPending
                          ? l.pendingReview
                          : stay.status.label,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
                              ? 'سيتم إشعار الاستقبال بطلب المغادرة. سيتحققون من الرصيد والطلبات المعلقة ثم يكملون المغادرة.'
                              : 'Reception will be notified. They will verify your balance and open requests, then complete checkout.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: stay.status == StayStatus.checkoutPending
                      ? null
                      : () {
                          store.requestCheckout(stay.id, app.guestId!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                l.isArabic
                                    ? 'تم إرسال طلب المغادرة ✓'
                                    : 'Checkout request sent ✓',
                              ),
                            ),
                          );
                          context.pop();
                        },
                  icon: const Icon(Icons.logout),
                  label: Text(l.checkoutRequest),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String k, String v, {Color? color}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

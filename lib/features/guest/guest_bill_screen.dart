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

class GuestBillScreen extends StatelessWidget {
  const GuestBillScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final app = context.watch<AppState>();
    final store = context.watch<HotelStore>();
    final theme = Theme.of(context);
    final stay = store.currentStayForGuest(app.guestId!)!;
    final charges = store.chargesForStay(stay.id);
    final payments = store.paymentsForStay(stay.id);
    final total = store.chargesTotal(stay.id);
    final paid = store.paymentsTotal(stay.id);
    final balance = total - paid;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l.myBill),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance summary
              Card(
                color:
                    (balance > 0
                            ? const Color(0xFFEF6C00)
                            : const Color(0xFF2E7D32))
                        .withOpacity(0.08),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Icon(
                        balance > 0
                            ? Icons.account_balance_wallet
                            : Icons.check_circle,
                        color: balance > 0
                            ? const Color(0xFFEF6C00)
                            : const Color(0xFF2E7D32),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.outstandingBalance,
                              style: theme.textTheme.titleSmall,
                            ),
                            Text(
                              Fmt.money(balance),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(l.charges, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              if (charges.isEmpty)
                EmptyState(
                  icon: Icons.receipt_outlined,
                  message: l.isArabic ? 'لا مبالغ' : 'No charges',
                )
              else
                ...charges.map(
                  (c) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.receipt_long_outlined),
                      title: Text(c.description),
                      subtitle: Text(
                        '${c.category} • ${Fmt.dateTime(c.at)}',
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            Fmt.money(c.net + c.tax),
                            style: theme.textTheme.titleSmall,
                          ),
                          Text(
                            '${l.taxes}: ${Fmt.money(c.tax)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(l.payments, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              if (payments.isEmpty)
                EmptyState(
                  icon: Icons.payments_outlined,
                  message: l.isArabic ? 'لا مدفوعات' : 'No payments',
                )
              else
                ...payments.map(
                  (p) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.payments_outlined),
                      title: Text('${_method(p.method, l)} • ${p.reference}'),
                      subtitle: Text(
                        Fmt.dateTime(p.at),
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: Text(
                        Fmt.money(p.amount),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              // Summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _row(context, l.charges, Fmt.money(total)),
                      _row(context, l.paid, Fmt.money(paid)),
                      const Divider(),
                      _row(
                        context,
                        l.remaining,
                        Fmt.money(balance),
                        bold: true,
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

  String _method(PaymentMethod m, L10n l) {
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
          Expanded(child: Text(k, style: theme.textTheme.bodyMedium)),
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

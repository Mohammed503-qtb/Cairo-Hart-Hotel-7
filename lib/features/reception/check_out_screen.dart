import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hotel_platform/core/constants.dart';
import 'package:hotel_platform/core/utils/format.dart';
import 'package:hotel_platform/data/models.dart';
import 'package:hotel_platform/data/store.dart';
import 'package:hotel_platform/l10n/app_localizations.dart';
import 'package:hotel_platform/shared/widgets/common_widgets.dart';

/// Reception checkout screen (PLAN §29): review balance, payments, requests,
/// then complete checkout. Also allows recording a final payment.
class CheckOutScreen extends StatefulWidget {
  final String stayId;
  const CheckOutScreen({super.key, required this.stayId});

  @override
  State<CheckOutScreen> createState() => _CheckOutScreenState();
}

class _CheckOutScreenState extends State<CheckOutScreen> {
  double _pay = 0;
  PaymentMethod _method = PaymentMethod.creditCard;
  final _refCtrl = TextEditingController();

  @override
  void dispose() {
    _refCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final store = context.watch<HotelStore>();
    final theme = Theme.of(context);
    final stay = store.stayById(widget.stayId);
    if (stay == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(icon: Icons.error_outline, message: l.noResults),
      );
    }
    final guest = store.guestById(stay.guestId);
    final room = store.roomById(stay.roomId)!;
    final t = store.roomTypeById(room.roomTypeId)!;
    final charges = store.chargesForStay(stay.id);
    final payments = store.paymentsForStay(stay.id);
    final total = store.chargesTotal(stay.id);
    final paid = store.paymentsTotal(stay.id);
    final balance = total - paid;
    final pending = store
        .requestsForStay(stay.id)
        .where(
          (r) =>
              r.status != RequestStatus.completed &&
              r.status != RequestStatus.cancelled &&
              r.status != RequestStatus.rejected,
        )
        .toList();

    final isDone = stay.status == StayStatus.checkedOut;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l.checkOut),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: stay.status.color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              guest?.name ?? '',
                              style: theme.textTheme.titleLarge,
                            ),
                            Text(
                              '${l.roomLabel} ${room.number} • ${l.isArabic ? t.nameAr : t.name} • ${stay.id}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      StatusChip(
                        label: stay.status.label,
                        color: stay.status.color,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: l.invoice,
                child: Column(
                  children: [
                    ...charges.map(
                      (c) => _row(c.description, Fmt.money(c.net + c.tax)),
                    ),
                    const Divider(),
                    _row(l.charges, Fmt.money(total), bold: true),
                    ...payments.map(
                      (p) => _row(
                        '${l.paid} — ${p.reference}',
                        '-' + Fmt.money(p.amount),
                      ),
                    ),
                    const Divider(),
                    _row(
                      l.remaining,
                      Fmt.money(balance),
                      bold: true,
                      color: balance > 0
                          ? const Color(0xFFEF6C00)
                          : const Color(0xFF2E7D32),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: l.requests,
                child: pending.isEmpty
                    ? Text(
                        l.isArabic ? 'لا طلبات معلقة' : 'No open requests',
                        style: theme.textTheme.bodyMedium,
                      )
                    : Column(
                        children: pending
                            .map(
                              (r) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  r.category.icon,
                                  color: r.status.color,
                                ),
                                title: Text(r.title),
                                trailing: StatusChip(
                                  label: r.status.label,
                                  color: r.status.color,
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
              if (!isDone) ...[
                const SizedBox(height: 16),
                if (balance > 0) ...[
                  SectionCard(
                    title: l.recordPayment,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: l.isArabic ? 'المبلغ' : 'Amount',
                                  prefixText: '${Brand.currencySymbol} ',
                                ),
                                onChanged: (v) => setState(
                                  () => _pay = double.tryParse(v) ?? 0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            DropdownButton<PaymentMethod>(
                              value: _method,
                              onChanged: (m) => setState(() => _method = m!),
                              items: [
                                DropdownMenuItem(
                                  value: PaymentMethod.creditCard,
                                  child: Text(l.isArabic ? 'بطاقة' : 'Card'),
                                ),
                                DropdownMenuItem(
                                  value: PaymentMethod.cash,
                                  child: Text(l.isArabic ? 'نقداً' : 'Cash'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _refCtrl,
                          decoration: InputDecoration(
                            labelText: l.isArabic ? 'المرجع' : 'Reference',
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              if (_pay <= 0) return;
                              store.recordPayment(
                                stayId: stay.id,
                                method: _method,
                                amount: _pay,
                                reference: _refCtrl.text.trim().isEmpty
                                    ? 'Final payment'
                                    : _refCtrl.text.trim(),
                                actor: 'reception',
                              );
                              setState(() => _pay = 0);
                              _refCtrl.clear();
                            },
                            icon: const Icon(Icons.payments_outlined),
                            label: Text(l.recordPayment),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Card(
                  color: const Color(0xFFC62828).withOpacity(0.06),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber,
                          color: Color(0xFFC62828),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l.confirmCheckoutMsg,
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
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: balance > 0
                        ? null
                        : () {
                            store.completeCheckout(
                              stayId: stay.id,
                              actor: 'reception',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l.isArabic
                                      ? 'تمت المغادرة ✓'
                                      : 'Checkout complete ✓',
                                ),
                              ),
                            );
                            context.pop();
                          },
                    icon: const Icon(Icons.logout),
                    label: Text(l.checkOut),
                  ),
                ),
                if (balance > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      l.isArabic ? 'يجب تصفية الرصيد المستحق قبل المغادرة.' : 'Outstanding balance must be settled before checkout.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFC62828),
                      ),
                    ),
                  ),
              ] else ...[
                const SizedBox(height: 16),
                Card(
                  color: const Color(0xFF2E7D32).withOpacity(0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF2E7D32),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l.isArabic
                                ? 'تمت المغادرة. الغرفة أصبحت بحاجة للتنظيف.'
                                : 'Checkout completed. Room moved to dirty.',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String k, String v, {bool bold = false, Color? color}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(k, style: theme.textTheme.bodyMedium)),
          Text(
            v,
            style:
                (bold
                        ? theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          )
                        : theme.textTheme.titleSmall)
                    ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

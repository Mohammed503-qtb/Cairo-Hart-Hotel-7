import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hotel_platform/core/constants.dart';
import 'package:hotel_platform/core/utils/format.dart';
import 'package:hotel_platform/data/models.dart';
import 'package:hotel_platform/data/store.dart';
import 'package:hotel_platform/l10n/app_localizations.dart';
import 'package:hotel_platform/shared/widgets/common_widgets.dart';

/// Reception reservation detail + check-in workflow (PLAN §12).
class ReservationDetailScreen extends StatefulWidget {
  final String reservationId;
  const ReservationDetailScreen({super.key, required this.reservationId});

  @override
  State<ReservationDetailScreen> createState() =>
      _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  String? _selectedRoomId;
  double _deposit = 0;
  PaymentMethod _depositMethod = PaymentMethod.creditCard;
  final _idCtrl = TextEditingController();

  @override
  void dispose() {
    _idCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final store = context.watch<HotelStore>();
    final theme = Theme.of(context);
    final res = store.reservationById(widget.reservationId);
    if (res == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(icon: Icons.error_outline, message: l.noResults),
      );
    }
    final guest = store.guestById(res.guestId);
    final type = store.roomTypeById(res.roomTypeId)!;
    final assignedRoom = res.assignedRoomId == null
        ? null
        : store.roomById(res.assignedRoomId!);
    final alreadyCheckedIn = res.status == ReservationStatus.checkedIn;
    final stay = res.stayId == null ? null : store.stayById(res.stayId!);
    final access = stay?.guestAccessId == null
        ? null
        : store.firstWhereOrNull(
            store.accesses,
            (a) => a.id == stay!.guestAccessId,
          );

    // candidate rooms for assignment
    final candidates = store.rooms.where((r) {
      if (r.roomTypeId != type.id) return false;
      if (!r.active) return false;
      if (r.status == RoomStatus.outOfOrder ||
          r.status == RoomStatus.outOfService)
        return false;
      if (r.status == RoomStatus.occupied) {
        return r.currentStayId != null; // allow to show but not selectable
      }
      return true;
    }).toList();
    _selectedRoomId =
        _selectedRoomId ??
        assignedRoom?.id ??
        (candidates.isEmpty ? null : candidates.first.id);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(res.id),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status header
              Card(
                color: res.status == ReservationStatus.cancelled
                    ? const Color(0xFFC62828).withOpacity(0.08)
                    : (alreadyCheckedIn
                          ? const Color(0xFF2E7D32).withOpacity(0.08)
                          : theme.colorScheme.primary.withOpacity(0.05)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        alreadyCheckedIn ? Icons.check_circle : Icons.event,
                        color: alreadyCheckedIn
                            ? const Color(0xFF2E7D32)
                            : theme.colorScheme.primary,
                      ),
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
                              '${res.id} • ${Fmt.dateShort(res.checkIn)} → ${Fmt.dateShort(res.checkOut)}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      StatusChip(
                        label: res.status.label,
                        color: alreadyCheckedIn
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFF1565C0),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: l.isArabic ? 'تفاصيل الحجز' : 'Reservation details',
                child: Column(
                  children: [
                    _row(
                      l.isArabic ? 'الغرفة' : 'Room type',
                      l.isArabic ? type.nameAr : type.name,
                    ),
                    _row(l.checkInDate, Fmt.date(res.checkIn)),
                    _row(l.checkOutDate, Fmt.date(res.checkOut)),
                    _row(
                      l.isArabic ? 'المدة' : 'Duration',
                      '${res.price.nights} ${res.price.nights == 1 ? l.night : l.nights}',
                    ),
                    _row(
                      l.isArabic ? 'النزلاء' : 'Guests',
                      '${res.adults} ${l.adults.toLowerCase()}' +
                          (res.children > 0
                              ? ' + ${res.children} ${l.children.toLowerCase()}'
                              : ''),
                    ),
                    const Divider(),
                    _row(l.subtotal, Fmt.money(res.price.subtotal)),
                    _row(l.taxes, Fmt.money(res.price.tax)),
                    _row(l.total, Fmt.money(res.price.total), bold: true),
                    _row(l.paymentMethod, _method(res.paymentMethod, l)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (alreadyCheckedIn && stay != null) ...[
                SectionCard(
                  title: l.isArabic ? 'الإقامة النشطة' : 'Active stay',
                  child: Column(
                    children: [
                      _row(l.isArabic ? 'رقم الإقامة' : 'Stay', stay.id),
                      _row(
                        l.roomLabel,
                        store.roomById(stay.roomId)?.number ?? '',
                      ),
                      _row(l.isArabic ? 'الحالة' : 'Status', stay.status.label),
                      if (access != null)
                        _row(
                          l.isArabic ? 'رمز الدخول' : 'Access code',
                          access.code,
                          bold: true,
                        ),
                      _row(
                        l.outstandingBalance,
                        Fmt.money(store.outstandingBalance(stay.id)),
                        color: store.outstandingBalance(stay.id) > 0
                            ? const Color(0xFFEF6C00)
                            : const Color(0xFF2E7D32),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            context.push('/reception/checkout/${stay.id}'),
                        icon: const Icon(Icons.logout),
                        label: Text(l.checkOut),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.task_outlined),
                        label: Text(l.requests),
                      ),
                    ),
                  ],
                ),
              ] else if (res.status == ReservationStatus.confirmed ||
                  res.status == ReservationStatus.pending) ...[
                // CHECK-IN WORKFLOW
                SectionCard(
                  title: l.verifyGuest,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _row(l.fullName, guest?.name ?? ''),
                      _row(l.email, guest?.email ?? ''),
                      _row(l.phone, guest?.phone ?? ''),
                      if (guest?.nationality != null)
                        _row(
                          l.isArabic ? 'الجنسية' : 'Nationality',
                          guest!.nationality!,
                        ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _idCtrl,
                        decoration: InputDecoration(
                          labelText: l.isArabic
                              ? 'رقم الهوية / الجواز'
                              : 'ID / Passport number',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: l.assignRoom,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: MediaQuery.sizeOf(context).width >= 700
                            ? 4
                            : 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.0,
                        children: candidates.map((r) {
                          final sel = _selectedRoomId == r.id;
                          final blocked = r.status == RoomStatus.occupied;
                          return Card(
                            color: sel
                                ? theme.colorScheme.primary.withOpacity(0.12)
                                : null,
                            child: InkWell(
                              onTap: blocked
                                  ? null
                                  : () =>
                                        setState(() => _selectedRoomId = r.id),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      r.number,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      r.status.label,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(color: r.status.color),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: l.isArabic
                      ? 'دفعة مقدمة (اختياري)'
                      : 'Deposit (optional)',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                () => _deposit = double.tryParse(v) ?? 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          DropdownButton<PaymentMethod>(
                            value: _depositMethod,
                            onChanged: (m) =>
                                setState(() => _depositMethod = m!),
                            items: [
                              DropdownMenuItem(
                                value: PaymentMethod.creditCard,
                                child: Text(l.isArabic ? 'بطاقة' : 'Card'),
                              ),
                              DropdownMenuItem(
                                value: PaymentMethod.cash,
                                child: Text(l.isArabic ? 'نقداً' : 'Cash'),
                              ),
                              DropdownMenuItem(
                                value: PaymentMethod.payAtHotel,
                                child: Text(l.payAtHotel),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _selectedRoomId == null
                        ? null
                        : () => _doCheckIn(res, context, l),
                    icon: const Icon(Icons.login),
                    label: Text(l.completeCheckIn),
                  ),
                ),
              ] else if (res.status == ReservationStatus.cancelled ||
                  res.status == ReservationStatus.noShow) ...[
                SectionCard(
                  title: l.isArabic ? 'الحالة' : 'Status',
                  child: Text(
                    res.status == ReservationStatus.cancelled
                        ? (l.isArabic ? 'ملغى' : 'Cancelled') +
                              (res.cancellationReason != null
                                  ? ' • ${res.cancellationReason}'
                                  : '')
                        : (l.isArabic ? 'لم يحضر' : 'No-show'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _doCheckIn(Reservation res, BuildContext context, L10n l) async {
    final store = context.read<HotelStore>();
    // assign selected room if different
    if (res.assignedRoomId != _selectedRoomId) {
      store.assignRoomToReservation(res.id, _selectedRoomId!);
    }
    // record guest id number
    final guest = store.guestById(res.guestId);
    if (guest != null && _idCtrl.text.trim().isNotEmpty) {
      guest.idNumber = _idCtrl.text.trim();
    }
    final stay = store.checkIn(
      reservationId: res.id,
      actor: 'reception',
      deposit: _deposit > 0 ? _deposit : null,
      depositMethod: _depositMethod,
    );
    final access = store.firstWhereOrNull(
      store.accesses,
      (a) => a.stayId == stay.id,
    );
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
            const SizedBox(width: 8),
            Text(l.isArabic ? 'تم تسجيل الدخول' : 'Checked-in'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l.isArabic ? "رقم الإقامة" : "Stay"}: ${stay.id}'),
            Text('${l.roomLabel}: ${store.roomById(stay.roomId)?.number}'),
            const SizedBox(height: 10),
            Text(l.isArabic ? 'رمز الدخول للنزيل:' : 'Guest access code:'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                access?.code ?? '',
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(letterSpacing: 6, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.isArabic
                  ? 'شارك هذا الرمز مع النزيل عبر WhatsApp.'
                  : 'Share this code with the guest via WhatsApp.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(c).pop(),
            child: Text(l.done),
          ),
        ],
      ),
    );
    if (!mounted) return;
    context.pop();
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

  Widget _row(String k, String v, {bool bold = false, Color? color}) {
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

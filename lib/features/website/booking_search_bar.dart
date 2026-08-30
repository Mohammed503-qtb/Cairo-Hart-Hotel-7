import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:hotel_platform/core/utils/format.dart';
import 'package:hotel_platform/l10n/app_localizations.dart';

/// Booking search bar used on Home and Rooms pages (PLAN §8.1).
class BookingSearchBar extends StatefulWidget {
  final VoidCallback? onSearch;
  final String? roomTypeId;

  const BookingSearchBar({super.key, this.onSearch, this.roomTypeId});

  @override
  State<BookingSearchBar> createState() => _BookingSearchBarState();
}

class _BookingSearchBarState extends State<BookingSearchBar> {
  late DateTime _checkIn;
  late DateTime _checkOut;
  int _adults = 2;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _checkIn = DateTime(n.year, n.month, n.day).add(const Duration(days: 1));
    _checkOut = _checkIn.add(const Duration(days: 3));
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 720;
          final children = [
            _field(
              icon: Icons.calendar_today_outlined,
              label: l.checkInDate,
              value: Fmt.dateShort(_checkIn),
              onTap: () => _pickDate(true),
            ),
            _field(
              icon: Icons.event_outlined,
              label: l.checkOutDate,
              value: Fmt.dateShort(_checkOut),
              onTap: () => _pickDate(false),
            ),
            _field(
              icon: Icons.person_outline,
              label: l.adults,
              value: '$_adults',
              onTap: _pickAdults,
            ),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _search,
                icon: const Icon(Icons.search),
                label: Text(l.checkAvailability),
              ),
            ),
          ];
          return Flex(
            direction: wide ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children
                .expand((w) => [
                      if (wide)
                        SizedBox(
                          width: 220,
                          child: w,
                        )
                      else
                        w,
                    ])
                .toList(),
          );
        },
      ),
    );
  }

  Widget _field({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.55),
                      )),
                  Text(value,
                      style: theme.textTheme.titleSmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(bool isCheckIn) async {
    final init = isCheckIn ? _checkIn : _checkOut;
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isCheckIn) {
        _checkIn = picked;
        if (!_checkOut.isAfter(_checkIn)) {
          _checkOut = _checkIn.add(const Duration(days: 1));
        }
      } else {
        if (picked.isAfter(_checkIn)) {
          _checkOut = picked;
        }
      }
    });
  }

  Future<void> _pickAdults() async {
    final v = await showModalBottomSheet<int>(
      context: context,
      builder: (c) => SizedBox(
        height: 320,
        child: ListView(
          children: List.generate(
            6,
            (i) => ListTile(
              title: Text('${i + 1} ${L10n.of(context).adults.toLowerCase()}'),
              trailing: _adults == i + 1
                  ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () => Navigator.of(c).pop(i + 1),
            ),
          ),
        ),
      ),
    );
    if (v != null) setState(() => _adults = v);
  }

  void _search() {
    if (widget.onSearch != null) {
      widget.onSearch!();
      return;
    }
    context.push('/website/booking', extra: {
      'roomTypeId': widget.roomTypeId,
      'checkIn': _checkIn,
      'checkOut': _checkOut,
      'adults': _adults,
    });
  }
}

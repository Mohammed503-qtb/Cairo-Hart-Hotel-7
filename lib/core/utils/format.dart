import 'dart:math';

import 'package:intl/intl.dart';

import 'package:hotel_platform/core/constants.dart';

/// Currency / date / number formatting helpers + access-code generators.
class Fmt {
  Fmt._();

  static String money(num amount, {String symbol = Brand.currencySymbol}) {
    final n = NumberFormat.currency(symbol: '$symbol ', decimalDigits: 2);
    return n.format(amount);
  }

  static String moneyShort(num amount) {
    return NumberFormat.currency(
      symbol: '${Brand.currencySymbol} ',
      decimalDigits: 0,
    ).format(amount);
  }

  static String date(DateTime d) => DateFormat('EEE, d MMM yyyy').format(d);
  static String dateShort(DateTime d) => DateFormat('d MMM yyyy').format(d);
  static String dateNum(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
  static String monthDay(DateTime d) => DateFormat('d MMM').format(d);
  static String time(DateTime d) => DateFormat('HH:mm').format(d);
  static String dateTime(DateTime d) =>
      DateFormat('d MMM yyyy, HH:mm').format(d);

  static int nights(DateTime checkIn, DateTime checkOut) {
    final n = checkOut.difference(checkIn).inDays;
    return n < 0 ? 0 : n;
  }

  // ---- Reservation / Stay / Request IDs ----
  static String reservationId(int seq) {
    final year = DateTime.now().year;
    return 'HTL-$year-${seq.toString().padLeft(6, '0')}';
  }

  static String stayId(int seq) {
    final year = DateTime.now().year;
    return 'ST-$year-${seq.toString().padLeft(6, '0')}';
  }

  static String requestId(int seq) => 'REQ-${seq.toString().padLeft(5, '0')}';
  static String chargeId(int seq) => 'CH-${seq.toString().padLeft(5, '0')}';
  static String paymentId(int seq) => 'PAY-${seq.toString().padLeft(5, '0')}';

  // ---- Access codes per PLAN_MOBILE-APK §5 ----
  // Guest:    H + 6 numeric digits + 2-char checksum  (e.g. H834729X7)
  // Reception: R + 6 numeric digits + 2-char checksum (e.g. R492671M3)
  // Admin:    A + 6 numeric digits + 2-char checksum  (e.g. A371849L9)
  // Website tracking: HTL-YYYY-NNNNNN (NOT valid for app login)

  /// 2-character alphanumeric checksum from the 6 numeric digits.
  /// Deterministic — same digits → same checksum.
  static String _checksum(String sixDigits) {
    var sum = 0;
    for (var i = 0; i < sixDigits.length; i++) {
      sum += (int.tryParse(sixDigits[i]) ?? 0) * (i + 1);
    }
    final alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ'; // no I/O for clarity
    final c1 = alphabet[sum % alphabet.length];
    final c2 = alphabet[(sum ~/ alphabet.length) % 10];
    return '$c1$c2';
  }

  static String _sixDigits(Random rng) {
    final n = 100000 + rng.nextInt(900000);
    return n.toString();
  }

  /// Generate a Guest access code (issued at check-in, tied to a stay).
  static String guestCode({Random? rng}) {
    final r = rng ?? Random();
    final d = _sixDigits(r);
    return 'H$d${_checksum(d)}';
  }

  /// Generate a Reception access code (admin-issued, shift-scoped).
  static String receptionCode({Random? rng}) {
    final r = rng ?? Random();
    final d = _sixDigits(r);
    return 'R$d${_checksum(d)}';
  }

  /// Generate an Admin access code (master-admin-issued).
  static String adminCode({Random? rng}) {
    final r = rng ?? Random();
    final d = _sixDigits(r);
    return 'A$d${_checksum(d)}';
  }

  /// Detect the code type from its prefix (PLAN_MOBILE-APK §5.2).
  /// Returns 'guest' | 'reception' | 'admin' | 'website' | null.
  static String? codeType(String code) {
    final c = code.trim().toUpperCase();
    if (c.isEmpty) return null;
    if (c.startsWith('H') && RegExp(r'^H\d{6}[A-Z0-9]{2}$').hasMatch(c)) {
      return 'guest';
    }
    if (c.startsWith('R') && RegExp(r'^R\d{6}[A-Z0-9]{2}$').hasMatch(c)) {
      return 'reception';
    }
    if (c.startsWith('A') && RegExp(r'^A\d{6}[A-Z0-9]{2}$').hasMatch(c)) {
      return 'admin';
    }
    if (c.startsWith('HTL-')) return 'website'; // website tracking code
    return null;
  }
}

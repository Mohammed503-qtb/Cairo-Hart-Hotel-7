import 'package:intl/intl.dart';

import 'package:hotel_platform/core/constants.dart';

/// Currency / date / number formatting helpers.
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
}

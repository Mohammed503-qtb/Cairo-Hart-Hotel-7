import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Cairo Heart Hotel — luxury hotel palette: deep gold + warm charcoal + cream
class AppTheme {
  static const Color primary = Color(0xFFB8975A); // warm gold
  static const Color primaryDark = Color(0xFF8C6E3F);
  static const Color accent = Color(0xFF1A1A1A); // charcoal
  static const Color background = Color(0xFFFAF7F2); // cream
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6357);
  static const Color success = Color(0xFF2E7D52);
  static const Color warning = Color(0xFFC77F2E);
  static const Color danger = Color(0xFFB23A3A);
  static const Color info = Color(0xFF2D6A8C);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary, brightness: Brightness.light,
      primary: primary, secondary: accent, surface: surface,
    ).copyWith(primary: primary, onPrimary: Colors.white),
    textTheme: GoogleFonts.cairoTextTheme(ThemeData.light().textTheme).apply(
      bodyColor: textPrimary, displayColor: textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: surface, foregroundColor: textPrimary,
      elevation: 0, centerTitle: true, surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary),
    ),
    cardTheme: CardThemeData(
      color: surface, elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary, foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 15),
        minimumSize: const Size(0, 48),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary, side: const BorderSide(color: primary),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primary, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: danger)),
      labelStyle: GoogleFonts.cairo(color: textSecondary, fontSize: 14),
      hintStyle: GoogleFonts.cairo(color: textSecondary, fontSize: 14),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: background, labelStyle: GoogleFonts.cairo(fontSize: 12, color: textPrimary),
      side: BorderSide(color: Colors.grey.shade200), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surface, selectedItemColor: primary, unselectedItemColor: textSecondary,
      type: BottomNavigationBarType.fixed, selectedLabelStyle: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700),
      unselectedLabelStyle: GoogleFonts.cairo(fontSize: 11),
    ),
    dividerTheme: DividerThemeData(color: Colors.grey.shade200, thickness: 1),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: primary, foregroundColor: Colors.white),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.dark).copyWith(primary: primary, onPrimary: Colors.white, surface: const Color(0xFF1E1E1E)),
    textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: Colors.white, displayColor: Colors.white,
    ),
    cardTheme: CardThemeData(color: const Color(0xFF1E1E1E), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), margin: EdgeInsets.zero),
    appBarTheme: AppBarTheme(backgroundColor: const Color(0xFF1E1E1E), foregroundColor: Colors.white, elevation: 0, centerTitle: true, surfaceTintColor: Colors.transparent),
    elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
    inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xFF2A2A2A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
  );
}

// Status color mapping
Color statusColor(String s) {
  final low = s.toLowerCase();
  if (['new','pending','draft','awaiting_confirmation','submitted','under_review','waiting'].any((k) => low.contains(k))) return AppTheme.warning;
  if (['confirmed','paid','completed','checked_in','approved','converted','contacted','done','assigned','in_progress'].any((k) => low.contains(k))) return AppTheme.success;
  if (['cancelled','rejected','failed','no_show','blocked','out_of_service','maintenance'].any((k) => low.contains(k))) return AppTheme.danger;
  if (['available','checked_out'].any((k) => low.contains(k))) return AppTheme.info;
  return AppTheme.textSecondary;
}

String statusLabelAr(String s) {
  const map = {
    'new':'جديد','assigned':'مُعيَّن','contacted':'تم التواصل','waiting_customer':'بانتظار العميل',
    'waiting_hotel':'بانتظار الفندق','confirmed':'مؤكد','converted':'مُحوَّل','closed':'مغلق','cancelled':'ملغى',
    'pending':'بانتظار','awaiting_confirmation':'بانتظار التأكيد','checked_in':'مسجّل دخول','checked_out':'مسجّل مغادرة',
    'completed':'مكتمل','rejected':'مرفوض','no_show':'لم يحضر','draft':'مسودة',
    'available':'متاحة','reserved':'محجوزة','occupied':'مشغولة','cleaning':'تنظيف','maintenance':'صيانة','blocked':'محجوبة','out_of_service':'خارج الخدمة',
    'paid':'مدفوع','partially_paid':'مدفوع جزئيًا','refunded':'مسترد','partially_refunded':'مسترد جزئيًا','active':'نشط','disabled':'معطّل',
    'published':'منشور','hidden':'مخفي','archived':'مؤرشف',
    'in_progress':'قيد التنفيذ','accepted':'مقبول','waiting':'بانتظار',
  };
  return map[s.toLowerCase()] ?? s;
}

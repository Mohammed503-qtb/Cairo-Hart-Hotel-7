import 'package:flutter/material.dart';

import 'package:hotel_platform/core/constants.dart';
import 'package:hotel_platform/data/store.dart';
import 'package:hotel_platform/l10n/app_localizations.dart';

/// Global app state: store + l10n + theme + current space/role/session.
/// Provided at root via MultiProvider.
class AppState extends ChangeNotifier {
  final HotelStore store = HotelStore();
  final L10n l10n = L10n();

  AppSpace _space = AppSpace.website;
  AppThemeMode _themeMode = AppThemeMode.system;
  bool _isDark = false;

  // Active sessions (demo: in-memory only)
  String? _guestId; // logged-in guest (after access code activation)
  String? _staffUserId; // logged-in staff (admin/reception)

  AppSpace get space => _space;
  AppThemeMode get themeMode => _themeMode;
  bool get isDark => _isDark;

  String? get guestId => _guestId;
  String? get staffUserId => _staffUserId;
  bool get isGuestSession => _guestId != null;
  bool get isStaffSession => _staffUserId != null;

  void setSpace(AppSpace s) {
    _space = s;
    notifyListeners();
  }

  void setThemeMode(AppThemeMode m) {
    _themeMode = m;
    _updateDark(WidgetsBinding.instance.platformDispatcher.platformBrightness);
    notifyListeners();
  }

  void _updateDark(Brightness b) {
    final dark = _themeMode == AppThemeMode.dark ||
        (_themeMode == AppThemeMode.system && b == Brightness.dark);
    _isDark = dark;
  }

  void applyPlatformBrightness(Brightness b) {
    _updateDark(b);
    notifyListeners();
  }

  void toggleLocale() => l10n.toggle();

  // -- Guest activation (PLAN §13) --
  /// Returns true on successful activation; sets guest session.
  bool activateGuest(String code) {
    final stay = store.validateAccessCode(code);
    if (stay == null) return false;
    _guestId = stay.guestId;
    _space = AppSpace.guest;
    notifyListeners();
    return true;
  }

  void signOutGuest() {
    _guestId = null;
    _space = AppSpace.website;
    notifyListeners();
  }

  // -- Staff login (demo: any username works) --
  bool loginStaff(String role) {
    final user = store.users.firstWhere((u) => u.role == role);
    _staffUserId = user.id;
    _space = role == 'admin' ? AppSpace.admin : AppSpace.reception;
    notifyListeners();
    return true;
  }

  /// Silent variant for use inside build phases (no notifyListeners, which
  /// is forbidden during build). Sets the session so the shell can render.
  void loginStaffSilent(String role) {
    if (isStaffSession) return;
    final user = store.users.firstWhere((u) => u.role == role);
    _staffUserId = user.id;
    _space = role == 'admin' ? AppSpace.admin : AppSpace.reception;
  }

  /// Silent guest activation for use inside build phases.
  void activateGuestSilent(String code) {
    if (isGuestSession) return;
    final stay = store.validateAccessCode(code);
    if (stay == null) return;
    _guestId = stay.guestId;
    _space = AppSpace.guest;
  }

  void signOutStaff() {
    _staffUserId = null;
    _space = AppSpace.website;
    notifyListeners();
  }
}

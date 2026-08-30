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
    final dark =
        _themeMode == AppThemeMode.dark ||
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

  // -- Staff login via access code (PLAN §4.1, §37) --
  /// Logs a staff member in by validating their admin-generated access code.
  /// Returns the role ('admin' | 'reception') on success, null on failure.
  String? loginStaffByCode(String code) {
    final sa = store.validateStaffCode(code);
    if (sa == null) return null;
    // Map the staff access to one of the seeded AppUser records by role.
    final user = store.users.firstWhere(
      (u) => u.role == sa.role,
      orElse: () => store.users.first,
    );
    _staffUserId = user.id;
    _space = sa.role == 'admin' ? AppSpace.admin : AppSpace.reception;
    notifyListeners();
    return sa.role;
  }

  // Legacy: direct role login (kept for demo deep-links only)
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

  // -- Unified login (PLAN §13 + §4.1) --
  /// The single entry point for the unified login screen. Detects whether the
  /// entered code is a guest access code (stay-tied 6-digit) or a staff access
  /// code (admin-generated, role-embedded), then activates the right session.
  /// Returns the resulting AppSpace, or null if the code is invalid.
  AppSpace? loginWithCode(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return null;
    // Try guest access code first (PLAN §13.2).
    if (activateGuest(trimmed)) return AppSpace.guest;
    // Try staff access code (PLAN §4.1).
    final role = loginStaffByCode(trimmed);
    if (role == 'admin') return AppSpace.admin;
    if (role == 'reception') return AppSpace.reception;
    return null;
  }

  /// Silent variant of loginWithCode for use inside build phases.
  void loginWithCodeSilent(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;
    final stay = store.validateAccessCode(trimmed);
    if (stay != null) {
      _guestId = stay.guestId;
      _space = AppSpace.guest;
      return;
    }
    final sa = store.validateStaffCode(trimmed);
    if (sa != null) {
      final user = store.users.firstWhere(
        (u) => u.role == sa.role,
        orElse: () => store.users.first,
      );
      _staffUserId = user.id;
      _space = sa.role == 'admin' ? AppSpace.admin : AppSpace.reception;
    }
  }

  void signOutStaff() {
    _staffUserId = null;
    _space = AppSpace.website;
    notifyListeners();
  }

  /// Sign out any session (guest or staff) — used by the unified logout.
  void signOut() {
    _guestId = null;
    _staffUserId = null;
    _space = AppSpace.website;
    notifyListeners();
  }
}

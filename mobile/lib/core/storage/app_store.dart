import 'dart:ui';
import 'package:flutter/material.dart';

/// Global app store: holds navigation state, auth, and the current "surface" (guest/admin).
class AppStore extends ChangeNotifier {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  bool _isAdmin = false;
  bool _isAuthed = false;

  bool get isAdmin => _isAdmin;
  bool get isAuthed => _isAuthed;

  void setAdminMode(bool v) { _isAdmin = v; notifyListeners(); }
  void setAuthed(bool v) { _isAuthed = v; notifyListeners(); }

  // Sign out + return to guest
  void signOut() {
    _isAuthed = false;
    _isAdmin = false;
    notifyListeners();
  }

  // After successful login, push to admin shell
  void enterAdmin() {
    _isAuthed = true;
    _isAdmin = true;
    notifyListeners();
  }

  // Return to guest mode (keep auth token for optional admin re-entry)
  void exitToGuest() {
    _isAdmin = false;
    notifyListeners();
  }

  // Open admin if authed, else go to login
  void openAdmin(BuildContext context) {
    if (_isAuthed) {
      setAdminMode(true);
      Navigator.of(context).pushNamedAndRemoveUntil('/admin', (_) => false);
    } else {
      Navigator.of(context).pushNamed('/login');
    }
  }
}

// Lightweight window utilities (kept for potential future use)
double devicePixelRatio() => PlatformDispatcher.instance.views.first.devicePixelRatio;

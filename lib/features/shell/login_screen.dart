import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hotel_platform/core/app_state.dart';
import 'package:hotel_platform/core/constants.dart';
import 'package:hotel_platform/l10n/app_localizations.dart';

/// Unified login screen (PLAN §13 + §4.1, §37).
///
/// The user enters a single access code. The system validates it and
/// determines the experience automatically:
///   • Guest access code (stay-tied 6-digit) → Guest App (mobile-first)
///   • Staff access code (admin-generated, role-embedded) → Reception or Admin
///     dashboard, depending on the code's role.
///
/// There is NO role-selection UI here — the code IS the authority. Staff
/// codes are generated from the admin control panel.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  AppSpace? _detected;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _detect() {
    final app = context.read<AppState>();
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _error = null);
      return;
    }
    // Live-detect the code type without activating a session (preview only).
    final stay = app.store.validateAccessCode(code);
    if (stay != null) {
      setState(() {
        _detected = AppSpace.guest;
        _error = null;
      });
      return;
    }
    final sa = app.store.validateStaffCode(code);
    if (sa != null) {
      setState(() {
        _detected = sa.role == 'admin' ? AppSpace.admin : AppSpace.reception;
        _error = null;
      });
      return;
    }
    setState(() {
      _detected = null;
    });
  }

  void _submit() {
    final app = context.read<AppState>();
    final l = L10n.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      final space = app.loginWithCode(_codeCtrl.text);
      if (!mounted) return;
      if (space == null) {
        setState(() {
          _loading = false;
          _error = l.invalidCodeUnified;
        });
        return;
      }
      switch (space) {
        case AppSpace.guest:
          context.go('/guest');
        case AppSpace.reception:
          context.go('/reception');
        case AppSpace.admin:
          context.go('/admin');
        case AppSpace.website:
          context.go('/');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final theme = Theme.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (kIsWeb) {
              context.go('/');
            } else {
              // Native app: nothing to go back to; clear.
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: Text(l.portalLogin),
        actions: [
          IconButton(
            icon: const Icon(Icons.translate),
            onPressed: () => context.read<AppState>().toggleLocale(),
            tooltip: l.switchLang,
          ),
          IconButton(
            icon: Icon(
              theme.brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () => context.read<AppState>().setThemeMode(
              theme.brightness == Brightness.dark
                  ? AppThemeMode.light
                  : AppThemeMode.dark,
            ),
            tooltip: l.switchTheme,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.vpn_key_outlined,
                      size: 52,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l.appName,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.portalLoginSub,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _codeCtrl,
                    onChanged: (_) => _detect(),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                    decoration: InputDecoration(
                      hintText: l.accessCodeHintUnified,
                      prefixIcon: const Icon(Icons.password_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  if (_detected != null) ...[
                    const SizedBox(height: 10),
                    _DetectedBadge(space: _detected!),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _submit,
                      icon: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.login),
                      label: Text(
                        l.login,
                        style: const TextStyle(fontSize: 17),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Card(
                    color: theme.colorScheme.primary.withOpacity(0.06),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l.demoCodes,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _DemoChip(
                                label: '204204',
                                role: l.guestApp,
                                color: const Color(0xFF2E7D32),
                                onTap: () {
                                  _codeCtrl.text = '204204';
                                  _detect();
                                },
                              ),
                              _DemoChip(
                                label: 'REC-200',
                                role: l.reception,
                                color: const Color(0xFFEF6C00),
                                onTap: () {
                                  _codeCtrl.text = 'REC-200';
                                  _detect();
                                },
                              ),
                              _DemoChip(
                                label: 'ADM-100',
                                role: l.admin,
                                color: const Color(0xFF6A1B9A),
                                onTap: () {
                                  _codeCtrl.text = 'ADM-100';
                                  _detect();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isMobile) ...[
                    const SizedBox(height: 16),
                    Text(
                      l.isArabic
                          ? 'تطبيق الهاتف: تجربة النزيل والاستقبال المحسّنة للجوال'
                          : 'Phone app: mobile-first guest & staff experience',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetectedBadge extends StatelessWidget {
  final AppSpace space;
  const _DetectedBadge({required this.space});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final theme = Theme.of(context);
    final (label, color, icon) = switch (space) {
      AppSpace.guest => (
        l.guestApp,
        const Color(0xFF2E7D32),
        Icons.phone_iphone,
      ),
      AppSpace.reception => (
        l.reception,
        const Color(0xFFEF6C00),
        Icons.support_agent,
      ),
      AppSpace.admin => (
        l.admin,
        const Color(0xFF6A1B9A),
        Icons.admin_panel_settings,
      ),
      AppSpace.website => (
        l.publicWebsite,
        theme.colorScheme.primary,
        Icons.public,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            l.isArabic ? 'سيتم الدخول إلى: $label' : 'Will sign in to: $label',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoChip extends StatelessWidget {
  final String label;
  final String role;
  final Color color;
  final VoidCallback onTap;
  const _DemoChip({
    required this.label,
    required this.role,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(Icons.copy, size: 16, color: color),
      label: Text(
        '$label ($role)',
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
      backgroundColor: color.withOpacity(0.08),
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }
}

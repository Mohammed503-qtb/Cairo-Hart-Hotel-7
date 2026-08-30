import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hotel_platform/core/app_state.dart';
import 'package:hotel_platform/l10n/app_localizations.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _activate() {
    final app = context.read<AppState>();
    setState(() {
      _loading = true;
      _error = null;
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      final ok = app.activateGuest(_codeCtrl.text.trim());
      if (!mounted) return;
      if (ok) {
        context.go('/guest');
      } else {
        setState(() {
          _loading = false;
          _error = L10n.of(context).invalidCode;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: Text(l.guestApp),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lock_open_outlined,
                        size: 44, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 18),
                  Text(l.enterAccessCode, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  Text(
                    l.isArabic
                        ? 'أدخل رمز الدخول المكوّن من 6 أرقام الذي حصلت عليه عند تسجيل الوصول'
                        : 'Enter the 6-digit access code provided at check-in',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _codeCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      letterSpacing: 12,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLength: 6,
                    decoration: InputDecoration(
                      hintText: '······',
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!,
                        style: TextStyle(color: theme.colorScheme.error)),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _loading ? null : _activate,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(l.activate),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Card(
                    color: theme.colorScheme.primary.withOpacity(0.06),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l.demoHint,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          IconButton(
                            tooltip: l.isArabic ? 'استخدام رمز تجريبي' : 'Use demo code',
                            icon: const Icon(Icons.auto_awesome),
                            onPressed: () => setState(() => _codeCtrl.text = '204204'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

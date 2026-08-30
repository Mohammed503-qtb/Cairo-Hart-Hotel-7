import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hotel_platform/core/app_state.dart';
import 'package:hotel_platform/l10n/app_localizations.dart';

class AdminLoginScreen extends StatelessWidget {
  const AdminLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final theme = Theme.of(context);
    final app = context.read<AppState>();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
        title: Text(l.admin),
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
                      color: const Color(0xFF6A1B9A).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.admin_panel_settings, size: 44, color: Color(0xFF6A1B9A)),
                  ),
                  const SizedBox(height: 18),
                  Text(l.adminSub, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 24),
                  Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        app.loginStaff('admin');
                        context.go('/admin');
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Color(0x1F6A1B9A),
                              child: Icon(Icons.admin_panel_settings, color: Color(0xFF6A1B9A)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Omar — ${l.admin}', style: theme.textTheme.titleMedium),
                                  Text(l.isArabic ? 'دخول تجريبي' : 'One-tap demo login', style: theme.textTheme.bodySmall),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
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

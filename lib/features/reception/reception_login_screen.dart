import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hotel_platform/core/app_state.dart';
import 'package:hotel_platform/l10n/app_localizations.dart';

class ReceptionLoginScreen extends StatefulWidget {
  const ReceptionLoginScreen({super.key});

  @override
  State<ReceptionLoginScreen> createState() => _ReceptionLoginScreenState();
}

class _ReceptionLoginScreenState extends State<ReceptionLoginScreen> {
  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final theme = Theme.of(context);
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: Text(l.reception),
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
                      color: const Color(0xFFEF6C00).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.support_agent,
                      size: 44,
                      color: Color(0xFFEF6C00),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l.receptionSub,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  _staffCard(
                    context,
                    name: 'Layla',
                    role: 'reception',
                    color: const Color(0xFFEF6C00),
                    icon: Icons.support_agent,
                  ),
                  const SizedBox(height: 12),
                  _staffCard(
                    context,
                    name: 'Omar',
                    role: 'admin',
                    color: const Color(0xFF6A1B9A),
                    icon: Icons.admin_panel_settings,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _staffCard(
    BuildContext context, {
    required String name,
    required String role,
    required Color color,
    required IconData icon,
  }) {
    final l = L10n.of(context);
    final app = context.read<AppState>();
    final roleLabel = role == 'admin' ? l.admin : l.reception;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          app.loginStaff(role);
          context.go(role == 'admin' ? '/admin' : '/reception');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.14),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$name — $roleLabel',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      l.isArabic
                          ? 'دخول تجريبي بضغطة واحدة'
                          : 'One-tap demo login',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

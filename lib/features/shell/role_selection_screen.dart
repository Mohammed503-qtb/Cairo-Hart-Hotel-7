import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hotel_platform/core/app_state.dart';
import 'package:hotel_platform/core/constants.dart';
import 'package:hotel_platform/l10n/app_localizations.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final app = context.watch<AppState>();
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface,
              theme.colorScheme.primary.withOpacity(0.10),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.hotel,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l.appName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displayMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l.tagline,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.chooseExperienceSub,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      l.chooseExperience,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 18),
                    ResponsiveRoleGrid(
                      spaces: [
                        _RoleData(
                          icon: Icons.public,
                          title: l.publicWebsite,
                          sub: l.publicWebsiteSub,
                          color: const Color(0xFF7D5A3C),
                          onTap: () {
                            app.setSpace(AppSpace.website);
                            context.go('/website');
                          },
                        ),
                        _RoleData(
                          icon: Icons.phone_iphone,
                          title: l.guestApp,
                          sub: l.guestAppSub,
                          color: const Color(0xFF2E7D32),
                          onTap: () {
                            app.setSpace(AppSpace.guest);
                            context.go('/guest/activate');
                          },
                        ),
                        _RoleData(
                          icon: Icons.support_agent,
                          title: l.reception,
                          sub: l.receptionSub,
                          color: const Color(0xFFEF6C00),
                          onTap: () {
                            app.setSpace(AppSpace.reception);
                            context.go('/reception/login');
                          },
                        ),
                        _RoleData(
                          icon: Icons.admin_panel_settings,
                          title: l.admin,
                          sub: l.adminSub,
                          color: const Color(0xFF6A1B9A),
                          onTap: () {
                            app.setSpace(AppSpace.admin);
                            context.go('/admin/login');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () => app.toggleLocale(),
                          icon: const Icon(Icons.translate),
                          label: Text(l.switchLang),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () {
                            app.setThemeMode(
                              app.isDark
                                  ? AppThemeMode.light
                                  : AppThemeMode.dark,
                            );
                          },
                          icon: Icon(
                            app.isDark
                                ? Icons.light_mode_outlined
                                : Icons.dark_mode_outlined,
                          ),
                          label: Text(l.switchTheme),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ResponsiveRoleGrid extends StatelessWidget {
  final List<_RoleData> spaces;
  const ResponsiveRoleGrid({super.key, required this.spaces});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossCount = width >= 900 ? 4 : (width >= 600 ? 2 : 1);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossCount,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: width >= 900 ? 0.95 : 1.6,
      children: spaces.map((d) => _RoleCard(data: d)).toList(),
    );
  }
}

class _RoleData {
  final IconData icon;
  final String title;
  final String sub;
  final Color color;
  final VoidCallback onTap;
  const _RoleData({
    required this.icon,
    required this.title,
    required this.sub,
    required this.color,
    required this.onTap,
  });
}

class _RoleCard extends StatelessWidget {
  final _RoleData data;
  const _RoleCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: data.onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: data.color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(data.icon, color: data.color, size: 26),
              ),
              const SizedBox(height: 14),
              Text(data.title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                data.sub,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

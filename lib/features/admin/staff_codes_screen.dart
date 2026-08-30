import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hotel_platform/core/utils/format.dart';
import 'package:hotel_platform/data/models.dart';
import 'package:hotel_platform/data/store.dart';
import 'package:hotel_platform/l10n/app_localizations.dart';
import 'package:hotel_platform/shared/widgets/common_widgets.dart';

/// Admin → Staff Access Codes management (PLAN §4.1, §37).
///
/// The admin generates login codes for reception and admin staff from this
/// screen. Staff enter these codes at the unified login screen; the system
/// validates the code and routes them to the role-specific dashboard.
class StaffCodesScreen extends StatefulWidget {
  const StaffCodesScreen({super.key});

  @override
  State<StaffCodesScreen> createState() => _StaffCodesScreenState();
}

class _StaffCodesScreenState extends State<StaffCodesScreen> {
  final _nameCtrl = TextEditingController();
  String _role = 'reception';
  int _validity = 90;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final store = context.watch<HotelStore>();
    final theme = Theme.of(context);
    final codes = store.staffAccesses;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l.staffCodes),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: theme.colorScheme.primary.withOpacity(0.06),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l.staffCodesSub,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Create form
              SectionCard(
                title: l.createStaffCode,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: l.staffName,
                        hintText: l.isArabic
                            ? 'مثال: ليلى (الاستقبال)'
                            : 'e.g. Layla (Front Desk)',
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _role,
                            decoration: InputDecoration(
                              labelText: l.role,
                              prefixIcon: const Icon(Icons.badge_outlined),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'reception',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.support_agent,
                                      color: Color(0xFFEF6C00),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(l.reception),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'admin',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.admin_panel_settings,
                                      color: Color(0xFF6A1B9A),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(l.admin),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (v) => setState(() => _role = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 140,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: l.validityDays,
                              prefixIcon: const Icon(Icons.event_outlined),
                            ),
                            controller: TextEditingController(
                              text: '$_validity',
                            ),
                            onChanged: (v) => setState(
                              () => _validity = int.tryParse(v) ?? 90,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _nameCtrl.text.trim().isEmpty
                            ? null
                            : () {
                                final sa = store.createStaffCode(
                                  staffName: _nameCtrl.text.trim(),
                                  role: _role,
                                  validityDays: _validity,
                                );
                                _nameCtrl.clear();
                                setState(() => _validity = 90);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${l.codeCreated}: ${sa.code}',
                                    ),
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.add),
                        label: Text(l.createStaffCode),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(l.staffCodes, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              if (codes.isEmpty)
                EmptyState(icon: Icons.vpn_key_outlined, message: l.noResults)
              else
                ...codes.map((sa) => _StaffCodeTile(sa: sa)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaffCodeTile extends StatelessWidget {
  final StaffAccess sa;
  const _StaffCodeTile({required this.sa});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final store = context.read<HotelStore>();
    final theme = Theme.of(context);
    final roleColor = sa.role == 'admin'
        ? const Color(0xFF6A1B9A)
        : const Color(0xFFEF6C00);
    final expired =
        sa.expiresAt != null && DateTime.now().isAfter(sa.expiresAt!);
    return Card(
      color: sa.active ? null : theme.colorScheme.onSurface.withOpacity(0.04),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: roleColor.withOpacity(0.14),
                  child: Icon(
                    sa.role == 'admin'
                        ? Icons.admin_panel_settings
                        : Icons.support_agent,
                    color: roleColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sa.staffName, style: theme.textTheme.titleMedium),
                      Text(
                        l.isArabic
                            ? 'الدور: ${sa.role == 'admin' ? l.admin : l.reception}'
                            : 'Role: ${sa.role == 'admin' ? l.admin : l.reception}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                StatusChip(
                  label: !sa.active
                      ? l.inactive
                      : expired
                      ? l.isArabic
                            ? 'منتهي'
                            : 'Expired'
                      : l.active,
                  color: !sa.active
                      ? const Color(0xFF9E9E9E)
                      : expired
                      ? const Color(0xFFC62828)
                      : const Color(0xFF2E7D32),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: roleColor.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.vpn_key, color: roleColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      sa.code,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: roleColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      // Clipboard not available without a package; show snackbar
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${l.isArabic ? "الرمز" : "Code"}: ${sa.code}',
                          ),
                        ),
                      );
                    },
                    tooltip: l.isArabic ? 'نسخ' : 'Copy',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _meta(
                  context,
                  Icons.event_available,
                  '${l.isArabic ? "أُنشئ" : "Created"}: ${Fmt.dateShort(sa.createdAt)}',
                ),
                _meta(
                  context,
                  Icons.event_busy,
                  '${l.expiresAt}: ${sa.expiresAt == null
                      ? l.isArabic
                            ? "غير محدد"
                            : "—"
                      : Fmt.dateShort(sa.expiresAt!)}',
                ),
                _meta(
                  context,
                  Icons.history,
                  '${l.lastUsed}: ${sa.lastUsedAt == null ? l.never : Fmt.dateTime(sa.lastUsedAt!)}',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (sa.active)
                  OutlinedButton.icon(
                    onPressed: () => store.regenerateStaffCode(sa.id),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(l.regenerate),
                  ),
                if (sa.active) const SizedBox(width: 8),
                if (sa.active)
                  OutlinedButton.icon(
                    onPressed: () => store.revokeStaffCode(sa.id),
                    icon: const Icon(Icons.block, size: 18),
                    label: Text(l.revoke),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/models.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/app_store.dart';

/// Profile / About screen — simple hotel info + admin entry/return.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiClient>();
    final store = context.watch<AppStore>();
    return Scaffold(
      appBar: AppBar(title: const Text('حول التطبيق')),
      body: FutureBuilder(
        future: api.get('/api/public/home'),
        builder: (context, AsyncSnapshot<dynamic> snap) {
          HotelSettings? settings;
          if (snap.hasData && snap.data is Map) {
            final d = Map<String, dynamic>.from(snap.data as Map);
            settings = HotelSettings.fromJson(Map<String, dynamic>.from(d['settings'] ?? const {}));
          }
          final error = snap.hasError ? snap.error.toString() : null;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _brandHeader(settings),
              const SizedBox(height: 16),
              if (error != null)
                _infoTile(Icons.warning_amber_outlined, 'تنبيه', 'تعذّر تحميل إعدادات الفندق', color: AppTheme.warning)
              else ...[
                if (settings?.addressAr != null && settings!.addressAr!.isNotEmpty)
                  _infoTile(Icons.location_on_outlined, 'العنوان', settings.addressAr!),
                if (settings?.phone != null && settings!.phone!.isNotEmpty)
                  _infoTile(Icons.phone_outlined, 'الهاتف', settings.phone!),
                if (settings?.email != null && settings!.email!.isNotEmpty)
                  _infoTile(Icons.email_outlined, 'البريد', settings.email!),
                if (settings?.whatsapp != null && settings!.whatsapp!.isNotEmpty)
                  _infoTile(Icons.chat_outlined, 'واتساب', settings.whatsapp!),
                if (settings?.checkinTime != null && settings!.checkinTime!.isNotEmpty)
                  _infoTile(Icons.login, 'تسجيل الدخول', 'من الساعة ${settings.checkinTime}'),
                if (settings?.checkoutTime != null && settings!.checkoutTime!.isNotEmpty)
                  _infoTile(Icons.logout, 'تسجيل المغادرة', 'حتى الساعة ${settings.checkoutTime}'),
              ],
              const SizedBox(height: 24),
              const _SectionTitle(text: 'الإدارة'),
              const SizedBox(height: 12),
              if (api.isAuthenticated) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    store.enterAdmin();
                    Navigator.of(context).pushNamedAndRemoveUntil('/admin', (_) => false);
                  },
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('العودة للوحة الإدارة'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    await api.clearToken();
                    store.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('تسجيل الخروج'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed('/login'),
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('دخول الإدارة'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
              ],
              const SizedBox(height: 24),
              const _SectionTitle(text: 'روابط سريعة'),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                ActionChip(label: const Text('الغرف'), avatar: const Icon(Icons.bed_outlined), onPressed: () => Navigator.of(context).pushNamed('/rooms')),
                ActionChip(label: const Text('حجوزاتي'), avatar: const Icon(Icons.receipt_long_outlined), onPressed: () => Navigator.of(context).pushNamed('/bookings')),
                ActionChip(label: const Text('الخدمات'), avatar: const Icon(Icons.room_service_outlined), onPressed: () => Navigator.of(context).pushNamed('/services')),
                ActionChip(label: const Text('تواصل معنا'), avatar: const Icon(Icons.support_agent_outlined), onPressed: () => Navigator.of(context).pushNamed('/contact')),
              ]),
              const SizedBox(height: 32),
              const Center(child: Text('الإصدار 1.0.0', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
              const SizedBox(height: 4),
              const Center(child: Text('© فندق قلب القاهرة', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
            ],
          );
        },
      ),
    );
  }

  Widget _brandHeader(HotelSettings? s) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Container(
          width: 84, height: 84,
          decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: const Icon(Icons.apartment, size: 40, color: AppTheme.primary),
        ),
        const SizedBox(height: 12),
        Text(s?.hotelNameAr ?? 'فندق قلب القاهرة', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary), textAlign: TextAlign.center),
        const SizedBox(height: 4),
        const Text('Cairo Heart Hotel', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
      ]),
    );
  }

  Widget _infoTile(IconData icon, String title, String value, {Color? color}) {
    final c = color ?? AppTheme.primary;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: c, size: 20),
        ),
        title: Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        subtitle: Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle({required this.text});
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.5));
}

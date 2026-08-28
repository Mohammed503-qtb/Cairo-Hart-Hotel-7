import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';

/// Admin settings — tabs: Hotel info, Feature flags, Roles & permissions, Localization.
/// Save button PATCHes /api/admin/settings with {settings, flags}.
class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});
  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 4, vsync: this);

  Map<String, String> _settings = {};
  List<Map<String, dynamic>> _flags = const [];
  List<Map<String, dynamic>> _roles = const [];
  List<String> _permissions = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = context.read<ApiClient>();
      final res = await api.get('/api/admin/settings') as Map<String, dynamic>;
      setState(() {
        _settings = Map<String, String>.from((res['settings'] as Map).map((k, v) => MapEntry(k.toString(), v.toString())));
        _flags = (res['flags'] as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _roles = (res['roles'] as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _permissions = (res['permissions'] as List? ?? const []).map((e) => e.toString()).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _set(String key, String value) => setState(() => _settings[key] = value);

  void _toggleFlag(String key, bool value) {
    setState(() {
      for (final f in _flags) {
        if (f['key'] == key) f['enabled'] = value;
      }
    });
  }

  Future<void> _save() async {
    try {
      final api = context.read<ApiClient>();
      final flagsMap = <String, bool>{};
      for (final f in _flags) {
        flagsMap[f['key'].toString()] = f['enabled'] as bool? ?? false;
      }
      await api.patch('/api/admin/settings', body: {
        'settings': _settings,
        'flags': flagsMap,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الإعدادات'), backgroundColor: AppTheme.success));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: ${e.toString()}'), backgroundColor: AppTheme.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
        ? const LoadingView(message: 'جارٍ تحميل الإعدادات')
        : _error != null
          ? ErrorView(message: 'تعذّر تحميل الإعدادات', onRetry: _load)
          : Column(children: [
              Container(
                color: AppTheme.surface,
                child: TabBar(
                  controller: _tab,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'معلومات الفندق'),
                    Tab(text: 'الميزات'),
                    Tab(text: 'الأدوار'),
                    Tab(text: 'العملة واللغة'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _HotelInfoTab(settings: _settings, onChange: _set, onSave: _save),
                    _FlagsTab(flags: _flags, onToggle: _toggleFlag, onSave: _save),
                    _RolesTab(roles: _roles, permissions: _permissions),
                    _LocalizationTab(settings: _settings, onChange: _set, onSave: _save),
                  ],
                ),
              ),
            ]),
    );
  }
}

class _HotelInfoTab extends StatefulWidget {
  final Map<String, String> settings;
  final void Function(String, String) onChange;
  final VoidCallback onSave;
  const _HotelInfoTab({required this.settings, required this.onChange, required this.onSave});

  @override
  State<_HotelInfoTab> createState() => _HotelInfoTabState();
}

class _HotelInfoTabState extends State<_HotelInfoTab> {
  late final TextEditingController _nameAr;
  late final TextEditingController _nameEn;
  late final TextEditingController _descAr;
  late final TextEditingController _phone;
  late final TextEditingController _whatsapp;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _maps;
  late final TextEditingController _checkin;
  late final TextEditingController _checkout;

  @override
  void initState() {
    super.initState();
    final s = widget.settings;
    _nameAr = TextEditingController(text: s['hotel.name_ar'] ?? '');
    _nameEn = TextEditingController(text: s['hotel.name_en'] ?? '');
    _descAr = TextEditingController(text: s['hotel.description_ar'] ?? '');
    _phone = TextEditingController(text: s['hotel.phone'] ?? '');
    _whatsapp = TextEditingController(text: s['hotel.whatsapp'] ?? '');
    _email = TextEditingController(text: s['hotel.email'] ?? '');
    _address = TextEditingController(text: s['hotel.address_ar'] ?? '');
    _maps = TextEditingController(text: s['hotel.maps_url'] ?? '');
    _checkin = TextEditingController(text: s['hotel.checkin_time'] ?? '14:00');
    _checkout = TextEditingController(text: s['hotel.checkout_time'] ?? '12:00');
  }

  @override
  void dispose() {
    _nameAr.dispose(); _nameEn.dispose(); _descAr.dispose(); _phone.dispose();
    _whatsapp.dispose(); _email.dispose(); _address.dispose(); _maps.dispose();
    _checkin.dispose(); _checkout.dispose();
    super.dispose();
  }

  void _push(String key, String value) {
    widget.onChange(key, value);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _Field('اسم الفندق بالعربية', _nameAr, (v) => _push('hotel.name_ar', v)),
        const SizedBox(height: 12),
        _Field('الاسم بالإنجليزية', _nameEn, (v) => _push('hotel.name_en', v)),
        const SizedBox(height: 12),
        _Field('الوصف', _descAr, (v) => _push('hotel.description_ar', v), maxLines: 3),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _Field('الهاتف', _phone, (v) => _push('hotel.phone', v), icon: Icons.phone_outlined)),
          const SizedBox(width: 10),
          Expanded(child: _Field('واتساب', _whatsapp, (v) => _push('hotel.whatsapp', v), icon: Icons.chat_outlined)),
        ]),
        const SizedBox(height: 12),
        _Field('البريد الإلكتروني', _email, (v) => _push('hotel.email', v), icon: Icons.mail_outline, keyboard: TextInputType.emailAddress),
        const SizedBox(height: 12),
        _Field('العنوان', _address, (v) => _push('hotel.address_ar', v), icon: Icons.location_on_outlined),
        const SizedBox(height: 12),
        _Field('رابط الخريطة', _maps, (v) => _push('hotel.maps_url', v), icon: Icons.map_outlined),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _Field('وقت الوصول', _checkin, (v) => _push('hotel.checkin_time', v), icon: Icons.login)),
          const SizedBox(width: 10),
          Expanded(child: _Field('وقت المغادرة', _checkout, (v) => _push('hotel.checkout_time', v), icon: Icons.logout)),
        ]),
        const SizedBox(height: 16),
        ElevatedButton.icon(onPressed: widget.onSave, icon: const Icon(Icons.save), label: const Text('حفظ التغييرات')),
      ]),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final void Function(String) onChanged;
  final IconData? icon;
  final TextInputType? keyboard;
  final int maxLines;
  const _Field(this.label, this.controller, this.onChanged, {this.icon, this.keyboard, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label, prefixIcon: icon != null ? Icon(icon, size: 18) : null),
      keyboardType: keyboard,
      maxLines: maxLines,
      onChanged: onChanged,
    );
  }
}

class _FlagsTab extends StatelessWidget {
  final List<Map<String, dynamic>> flags;
  final void Function(String, bool) onToggle;
  final VoidCallback onSave;
  const _FlagsTab({required this.flags, required this.onToggle, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final flagLabels = <String, String>{
      'online_payment': 'الدفع الإلكتروني',
      'reviews': 'مراجعات الضيوف',
      'offers': 'العروض',
      'service_requests': 'طلبات الخدمات',
      'guest_accounts': 'حسابات الضيوف',
      'gallery': 'المعرض',
    };
    return Column(children: [
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: flags.length,
          itemBuilder: (context, i) {
            final f = flags[i];
            final key = f['key'].toString();
            final enabled = f['enabled'] as bool? ?? false;
            final label = f['label']?.toString() ?? flagLabels[key] ?? key;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: SwitchListTile(
                title: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                subtitle: Text(key, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                value: enabled,
                onChanged: (v) => onToggle(key, v),
                activeThumbColor: AppTheme.primary,
              ),
            );
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: onSave, icon: const Icon(Icons.save), label: const Text('حفظ الميزات'))),
      ),
    ]);
  }
}

class _RolesTab extends StatelessWidget {
  final List<Map<String, dynamic>> roles;
  final List<String> permissions;
  const _RolesTab({required this.roles, required this.permissions});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: roles.length,
      itemBuilder: (context, i) {
        final r = roles[i];
        final perms = (r['permissions'] as List? ?? const []).map((e) => e.toString()).toList();
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.badge_outlined, color: AppTheme.primary, size: 18),
            ),
            title: Text(r['nameAr']?.toString() ?? r['key'].toString(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            subtitle: Text(r['key']?.toString() ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('الصلاحيات', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  if (perms.isEmpty)
                    const Text('لا توجد صلاحيات.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary))
                  else
                    Wrap(spacing: 4, runSpacing: 4, children: perms.map((p) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppTheme.info.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                      child: Text(p, style: const TextStyle(fontSize: 10, color: AppTheme.info, fontWeight: FontWeight.w700)),
                    )).toList()),
                  const SizedBox(height: 12),
                  const Text('كل الصلاحيات المتاحة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Wrap(spacing: 4, runSpacing: 4, children: permissions.map((p) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(4)),
                    child: Text(p, style: TextStyle(fontSize: 9, color: perms.contains(p) ? AppTheme.success : AppTheme.textSecondary, fontWeight: perms.contains(p) ? FontWeight.w800 : FontWeight.normal)),
                  )).toList()),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LocalizationTab extends StatefulWidget {
  final Map<String, String> settings;
  final void Function(String, String) onChange;
  final VoidCallback onSave;
  const _LocalizationTab({required this.settings, required this.onChange, required this.onSave});

  @override
  State<_LocalizationTab> createState() => _LocalizationTabState();
}

class _LocalizationTabState extends State<_LocalizationTab> {
  late final TextEditingController _symbol;
  late final TextEditingController _lang;

  @override
  void initState() {
    super.initState();
    _symbol = TextEditingController(text: widget.settings['localization.currency_symbol_ar'] ?? 'ر.ي');
    _lang = TextEditingController(text: widget.settings['localization.language'] ?? 'ar');
  }

  @override
  void dispose() {
    _symbol.dispose();
    _lang.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _Field('رمز العملة', _symbol, (v) => widget.onChange('localization.currency_symbol_ar', v), icon: Icons.payments_outlined),
        const SizedBox(height: 12),
        _Field('اللغة الافتراضية', _lang, (v) => widget.onChange('localization.language', v), icon: Icons.language),
        const SizedBox(height: 16),
        ElevatedButton.icon(onPressed: widget.onSave, icon: const Icon(Icons.save), label: const Text('حفظ')),
      ]),
    );
  }
}

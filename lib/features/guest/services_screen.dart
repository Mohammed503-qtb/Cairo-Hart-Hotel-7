import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hotel_platform/core/app_state.dart';
import 'package:hotel_platform/core/constants.dart';
import 'package:hotel_platform/core/utils/format.dart';
import 'package:hotel_platform/data/models.dart';
import 'package:hotel_platform/data/store.dart';
import 'package:hotel_platform/l10n/app_localizations.dart';
import 'package:hotel_platform/shared/widgets/common_widgets.dart';

/// Guest service catalog + custom request (PLAN §15, §16).
class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  ServiceCategory? _filter;
  Service? _selected;
  final _descCtrl = TextEditingController();
  bool _urgent = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final store = context.watch<HotelStore>();
    final theme = Theme.of(context);
    final app = context.watch<AppState>();
    final stay = store.currentStayForGuest(app.guestId!)!;

    final services = store.services.where((s) {
      if (_filter == null) return true;
      return s.category == _filter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l.services),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category filter
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Wrap(
                  spacing: 8,
                  children: [null, ...ServiceCategory.values].map((c) {
                    final sel = _filter == c;
                    final label = c == null
                        ? (l.isArabic ? 'الكل' : 'All')
                        : (l.isArabic ? c.labelAr : c.label);
                    return FilterChip(
                      label: Text(label),
                      selected: sel,
                      onSelected: (_) =>
                          setState(() => _filter = sel ? null : c),
                      avatar: c == null ? null : Icon(c.icon, size: 16),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: MediaQuery.sizeOf(context).width >= 700 ? 3 : 1,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: MediaQuery.sizeOf(context).width >= 700
                    ? 2.6
                    : 2.4,
                children: services.map((s) {
                  final sel = _selected?.id == s.id;
                  return Card(
                    color: sel
                        ? theme.colorScheme.primary.withOpacity(0.08)
                        : null,
                    child: InkWell(
                      onTap: () => setState(() => _selected = s),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              s.category.icon,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    l.isArabic ? s.nameAr : s.name,
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  Text(
                                    l.isArabic
                                        ? s.category.labelAr
                                        : s.category.label,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (sel)
                              Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.primary,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text(l.newRequest, style: theme.textTheme.titleLarge),
              const SizedBox(height: 10),
              TextField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l.description,
                  hintText: l.isArabic
                      ? 'مثال: أحتاج بطانية إضافية وزجاجتي ماء.'
                      : 'e.g. I need an extra blanket and two bottles of water.',
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _urgent,
                onChanged: (v) => setState(() => _urgent = v),
                title: Text(l.urgent),
                secondary: Icon(
                  Icons.priority_high,
                  color: _urgent ? const Color(0xFFC62828) : null,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: () => _submit(stay),
                  icon: const Icon(Icons.send),
                  label: Text(l.sendRequest),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit(Stay stay) {
    final l = L10n.of(context);
    if (_selected == null && _descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l.isArabic
                ? 'اختر خدمة أو اكتب وصفاً'
                : 'Pick a service or write a description',
          ),
        ),
      );
      return;
    }
    final store = context.read<HotelStore>();
    final category = _selected?.category ?? ServiceCategory.guestServices;
    final title = _selected != null
        ? (l.isArabic ? _selected!.nameAr : _selected!.name)
        : (l.isArabic ? 'طلب مخصص' : 'Custom request');
    store.createRequest(
      stayId: stay.id,
      serviceId: _selected?.id,
      category: category,
      title: title,
      description: _descCtrl.text.trim().isEmpty
          ? title
          : _descCtrl.text.trim(),
      priority: _urgent ? RequestPriority.urgent : RequestPriority.normal,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.isArabic ? 'تم إرسال الطلب ✓' : 'Request sent ✓'),
      ),
    );
    context.pop();
  }
}

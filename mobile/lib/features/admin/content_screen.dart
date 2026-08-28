import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/common.dart';

/// Content management center — homepage sections visibility/sort,
/// FAQ list, policies, gallery items.
///
/// Backend supports PATCHing content sections only (visible, sortOrder,
/// titleAr, titleEn, config). FAQs, policies, and gallery items are shown
/// as read-only lists (no create/edit/delete endpoints yet).
class ContentScreen extends StatefulWidget {
  const ContentScreen({super.key});
  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = context.read<ApiClient>();
      final res = await api.get('/api/admin/content') as Map<String, dynamic>;
      setState(() { _data = res; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _toggleSection(Map<String, dynamic> section, bool value) async {
    try {
      final api = context.read<ApiClient>();
      await api.patch('/api/admin/content', body: {
        'sectionKey': section['key'],
        'visible': value,
      });
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value ? 'تم إظهار القسم' : 'تم إخفاء القسم'), backgroundColor: AppTheme.success));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: ${e.toString()}'), backgroundColor: AppTheme.danger));
    }
  }

  Future<void> _editSectionTitle(Map<String, dynamic> section) async {
    final arCtrl = TextEditingController(text: section['titleAr']?.toString() ?? '');
    final enCtrl = TextEditingController(text: section['titleEn']?.toString() ?? '');
    final orderCtrl = TextEditingController(text: section['sortOrder']?.toString() ?? '0');
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('تعديل: ${section['titleAr']}'),
        content: SizedBox(
          width: 360,
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(controller: arCtrl, decoration: const InputDecoration(labelText: 'العنوان بالعربية'), validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null),
              const SizedBox(height: 10),
              TextFormField(controller: enCtrl, decoration: const InputDecoration(labelText: 'العنوان بالإنجليزية'), validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null),
              const SizedBox(height: 10),
              TextFormField(controller: orderCtrl, decoration: const InputDecoration(labelText: 'ترتيب العرض'), keyboardType: TextInputType.number),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () {
            if (formKey.currentState!.validate()) Navigator.pop(c, true);
          }, child: const Text('حفظ')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final api = context.read<ApiClient>();
      await api.patch('/api/admin/content', body: {
        'sectionKey': section['key'],
        'titleAr': arCtrl.text.trim(),
        'titleEn': enCtrl.text.trim(),
        'sortOrder': int.tryParse(orderCtrl.text) ?? 0,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث القسم'), backgroundColor: AppTheme.success));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: ${e.toString()}'), backgroundColor: AppTheme.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
          ? const LoadingView(message: 'جارٍ تحميل المحتوى')
          : _error != null
            ? ErrorView(message: 'تعذّر تحميل المحتوى', onRetry: _load)
            : _data == null
              ? const EmptyView(message: 'لا توجد بيانات', icon: Icons.article_outlined)
              : CustomScrollView(slivers: [
                  _buildHeader('أقسام الصفحة الرئيسية', icon: Icons.article_outlined),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    sliver: SliverList.builder(
                      itemCount: (_data!['sections'] as List? ?? const []).length,
                      itemBuilder: (context, i) {
                        final s = (_data!['sections'] as List)[i] as Map<String, dynamic>;
                        return _SectionTile(
                          section: s,
                          onToggle: (v) => _toggleSection(s, v),
                          onEdit: () => _editSectionTitle(s),
                        );
                      },
                    ),
                  ),
                  _buildHeader('الأسئلة الشائعة', icon: Icons.help_outline),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    sliver: SliverList.builder(
                      itemCount: (_data!['faqs'] as List? ?? const []).length,
                      itemBuilder: (context, i) {
                        final f = (_data!['faqs'] as List)[i] as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.question_answer_outlined, color: AppTheme.primary, size: 20),
                            title: Text(f['questionAr']?.toString() ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                            subtitle: Text(f['answerAr']?.toString() ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ),
                        );
                      },
                    ),
                  ),
                  _buildHeader('السياسات', icon: Icons.policy_outlined),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    sliver: SliverList.builder(
                      itemCount: (_data!['policies'] as List? ?? const []).length,
                      itemBuilder: (context, i) {
                        final p = (_data!['policies'] as List)[i] as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.description_outlined, color: AppTheme.info, size: 20),
                            title: Text(p['titleAr']?.toString() ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                            subtitle: Text(p['bodyAr']?.toString() ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary), maxLines: 3, overflow: TextOverflow.ellipsis),
                          ),
                        );
                      },
                    ),
                  ),
                  _buildHeader('المعرض', icon: Icons.photo_library_outlined),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 160, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1),
                      delegate: SliverChildBuilderDelegate(
                        childCount: (_data!['gallery'] as List? ?? const []).length,
                        (context, i) {
                          final g = (_data!['gallery'] as List)[i] as Map<String, dynamic>;
                          final url = g['url'] as String?;
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: HotelNetworkImage(url: url, aspectRatio: 1, radius: BorderRadius.circular(12), fit: BoxFit.cover),
                          );
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ]),
      ),
    );
  }

  Widget _buildHeader(String title, {IconData icon = Icons.article_outlined}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(children: [
          Icon(icon, color: AppTheme.primary, size: 18),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        ]),
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  final Map<String, dynamic> section;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  const _SectionTile({required this.section, required this.onToggle, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final visible = section['visible'] as bool? ?? true;
    final sortOrder = section['sortOrder']?.toString() ?? '0';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 36, height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Text(sortOrder, style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary, fontSize: 12)),
        ),
        title: Row(children: [
          Expanded(child: Text(section['titleAr']?.toString() ?? section['key'].toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(section['key']?.toString() ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primary), onPressed: onEdit, tooltip: 'تعديل', visualDensity: VisualDensity.compact),
          Switch(value: visible, onChanged: onToggle, activeThumbColor: AppTheme.primary),
        ]),
      ),
    );
  }
}

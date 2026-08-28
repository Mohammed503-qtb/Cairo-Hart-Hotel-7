import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/app_store.dart';

/// Admin login — full Scaffold route pushed from /login.
/// Authenticates against /api/auth/login, stores token via ApiClient.setToken,
/// then calls AppStore.enterAdmin() and navigates to /admin.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});
  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController(text: 'admin@cairoheart.ye');
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final api = context.read<ApiClient>();
      final res = await api.post('/api/auth/login', body: {
        'email': _emailCtrl.text.trim(),
        'password': _passCtrl.text,
      }) as Map<String, dynamic>;
      final token = res['token'] as String?;
      if (token == null || token.isEmpty) throw 'لم يتم استلام رمز الدخول';
      await api.setToken(token);
      if (!mounted) return;
      context.read<AppStore>().enterAdmin();
      Navigator.of(context).pushNamedAndRemoveUntil('/admin', (Route<dynamic> r) => false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('فشل الدخول: ${e.toString()}'),
          backgroundColor: AppTheme.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('دخول الإدارة'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 72, height: 72,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8))],
                      ),
                      child: const Icon(Icons.hotel, color: Colors.white, size: 36),
                    ),
                    const Text('فندق قلب القاهرة', textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                    const SizedBox(height: 4),
                    const Text('لوحة تحكم الإدارة', textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    const SizedBox(height: 28),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _emailCtrl,
                              decoration: const InputDecoration(
                                labelText: 'البريد الإلكتروني',
                                prefixIcon: Icon(Icons.mail_outline),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: (v) {
                                final s = v?.trim() ?? '';
                                if (s.isEmpty || !s.contains('@') || !s.contains('.')) return 'بريد إلكتروني غير صحيح';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passCtrl,
                              decoration: InputDecoration(
                                labelText: 'كلمة المرور',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                              ),
                              obscureText: _obscure,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              validator: (v) => (v == null || v.isEmpty) ? 'كلمة المرور مطلوبة' : null,
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _submit,
                                child: _loading
                                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('تسجيل الدخول'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(child: Text('يستخدم هذا الحساب موظفي الفندق فقط. لدخول الضيف ارجع إلى الواجهة الرئيسية.',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('العودة إلى واجهة الضيف'),
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

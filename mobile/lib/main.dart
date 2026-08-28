import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/theme.dart';
import 'app/app_router.dart';
import 'core/network/api_client.dart';
import 'core/storage/app_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiClient();
  await api.init();
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider<AppStore>.value(value: AppStore()),
    Provider<ApiClient>.value(value: api),
  ], child: const CairoHeartApp()));
}

class CairoHeartApp extends StatelessWidget {
  const CairoHeartApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<AppStore>(builder: (context, store, _) {
      return MaterialApp(
        title: 'فندق قلب القاهرة',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,
        locale: const Locale('ar'),
        builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: store.isAuthed ? '/admin' : '/home',
        navigatorKey: store.navigatorKey,
      );
    });
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hotel_platform/core/app_state.dart';
import 'package:hotel_platform/core/router.dart';
import 'package:hotel_platform/core/theme.dart';
import 'package:hotel_platform/data/store.dart';
import 'package:hotel_platform/l10n/app_localizations.dart';

void main() {
  runApp(const HotelPlatformApp());
}

class HotelPlatformApp extends StatefulWidget {
  const HotelPlatformApp({super.key});

  @override
  State<HotelPlatformApp> createState() => _HotelPlatformAppState();
}

class _HotelPlatformAppState extends State<HotelPlatformApp>
    with WidgetsBindingObserver {
  final AppState _app = AppState();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _app.applyPlatformBrightness(
      WidgetsBinding.instance.platformDispatcher.platformBrightness,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    _app.applyPlatformBrightness(
      WidgetsBinding.instance.platformDispatcher.platformBrightness,
    );
    super.didChangePlatformBrightness();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: _app),
        ChangeNotifierProvider<L10n>.value(value: _app.l10n),
        ChangeNotifierProvider<HotelStore>.value(value: _app.store),
      ],
      child: L10n.scope(
        l10n: _app.l10n,
        child: Builder(
          builder: (context) {
            final app = context.watch<AppState>();
            return MaterialApp.router(
              title: 'Lumière Grand Hotel',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: app.isDark ? ThemeMode.dark : ThemeMode.light,
              routerConfig: buildRouter(app),
              builder: (context, child) {
                final l10n = context.watch<L10n>();
                return Directionality(
                  textDirection: l10n.dir,
                  child: child ?? const SizedBox(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/drawing_storage.dart';
import 'services/entitlement_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // A child must never see a red error screen.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('Widget error: ${details.exception}');
    return const _FriendlyError();
  };

  // Startup work is defensive: if any single step fails the app still opens.
  try {
    await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  } catch (e) {
    debugPrint('Orientation setup skipped: $e');
  }

  try {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  } catch (e) {
    debugPrint('System UI mode skipped: $e');
  }

  try {
    await EntitlementService.instance.load();
  } catch (e) {
    debugPrint('Entitlement load failed, continuing free: $e');
  }

  try {
    await DrawingStorage.instance.init();
  } catch (e) {
    debugPrint('Storage init failed, drawings disabled: $e');
  }

  runApp(const ToddlerColoringApp());
}

class ToddlerColoringApp extends StatelessWidget {
  const ToddlerColoringApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baby Coloring: Toddler Games',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
      builder: (BuildContext context, Widget? child) {
        // Fire tablets let parents set very large system fonts. Clamp the
        // scale so buttons and labels can never overflow the layout.
        final MediaQueryData data = MediaQuery.of(context);
        return MediaQuery(
          data: data.copyWith(
            textScaler: data.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.2,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

class _FriendlyError extends StatelessWidget {
  const _FriendlyError();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppTheme.paper,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.color_lens_outlined, size: 64, color: AppTheme.brand),
              SizedBox(height: 12),
              Text(
                'Oops! Let us try that again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

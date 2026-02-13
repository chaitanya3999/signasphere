import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import core configurations
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
// Initial widget route handling
// Import core configurations checked above
import 'core/theme/theme_controller.dart';

/// Global variable to store the initial widget deep-link route
String? _widgetInitialRoute;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Check for widget deep-link route
  try {
    const channel = MethodChannel('com.example.signasphere/navigation');
    _widgetInitialRoute = await channel.invokeMethod<String?>('getInitialRoute');
  } catch (_) {
    // Not launched from widget or platform doesn't support it
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appRouterProvider.overrideWithValue(createAppRouter(prefs)),
      ],
      child: const SignasphereApp(),
    ),
  );
}

class SignasphereApp extends ConsumerStatefulWidget {
  const SignasphereApp({super.key});

  @override
  ConsumerState<SignasphereApp> createState() => _SignasphereAppState();
}

class _SignasphereAppState extends ConsumerState<SignasphereApp> {
  @override
  void initState() {
    super.initState();
    // Navigate to widget route after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = _widgetInitialRoute;
      if (route != null && route.isNotEmpty) {
        ref.read(appRouterProvider).go(route);
        _widgetInitialRoute = null; // Consume the route
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'SignSphere',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

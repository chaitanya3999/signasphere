import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/splash_screen.dart';
import '../../features/live_sign/presentation/live_sign_screen.dart';
import '../../features/avatar/presentation/avatar_screen.dart';
import '../../features/conversation/presentation/conversation_screen.dart';
import '../../features/learn/presentation/learn_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/home/presentation/main_scaffold.dart';
import '../../features/emergency/screens/emergency_hub_screen.dart';
import '../../features/emergency/screens/emergency_contacts_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/auth_gate.dart';

// Private navigators
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

// Routes that don't require login
const _publicRoutes = ['/splash', '/auth-gate', '/login', '/register'];

GoRouter createAppRouter(SharedPreferences prefs) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final location = state.uri.toString();

      // Allow public routes
      if (_publicRoutes.contains(location)) return null;

      // Check session
      final userId = prefs.getString('logged_in_user');
      final isLoggedIn = userId != null && userId.isNotEmpty;

      if (!isLoggedIn) return '/login';

      return null; // allow
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth-gate',
        builder: (context, state) => const AuthGate(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/emergency',
        builder: (context, state) => const EmergencyHubScreen(),
      ),
      GoRoute(
        path: '/emergency/contacts',
        builder: (context, state) => const EmergencyContactsScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/live-sign',
            builder: (context, state) => const LiveSignScreen(),
          ),
          GoRoute(
            path: '/avatar',
            builder: (context, state) => const AvatarScreen(),
          ),
          GoRoute(
            path: '/conversation',
            builder: (context, state) => const ConversationScreen(),
          ),
          GoRoute(
            path: '/learn',
            builder: (context, state) => const LearnScreen(),
          ),
        ],
      ),
    ],
  );
}

// Provider for the router — requires SharedPreferences to check auth
final appRouterProvider = Provider<GoRouter>((ref) {
  throw UnimplementedError('Must be overridden');
});

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/splash_screen.dart';
import '../../features/live_sign/presentation/live_sign_screen.dart';
import '../../features/avatar/presentation/avatar_screen.dart';
import '../../features/conversation/presentation/conversation_screen.dart';
import '../../features/learn/presentation/learn_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/home/presentation/main_scaffold.dart';

// Private navigators
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
       path: '/settings',
       builder: (context, state) => const SettingsScreen(),
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

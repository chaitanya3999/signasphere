import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/theme/theme_controller.dart';
import '../../auth/controllers/auth_controller.dart';

// Riverpod 3: StateProvider -> Notifier
final demoModeProvider =
    NotifierProvider<DemoModeNotifier, bool>(DemoModeNotifier.new);

class DemoModeNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  void toggle(bool value) => state = value;
}

final systemHealthProvider = FutureProvider<Map<String, bool>>((ref) async {
  ref.watch(demoModeProvider);
  final cameraStatus = await Permission.camera.status;
  final micStatus = await Permission.microphone.status;
  await Future.delayed(const Duration(milliseconds: 500));
  return {
    "Camera": cameraStatus.isGranted,
    "Microphone": micStatus.isGranted,
    "AI Engine": true,
  };
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDemoMode = ref.watch(demoModeProvider);
    final healthAsync = ref.watch(systemHealthProvider);
    final user = ref.watch(authControllerProvider).valueOrNull;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Settings & Status'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).scaffoldBackgroundColor,
                  Colors.blueGrey.withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 100, 16, 100),
            children: [
              // ── User Profile Card ──
              if (user != null) ...[
                const Text("PROFILE",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.5)),
                const SizedBox(height: 8),
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  opacity: 0.1,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor:
                            Color(user.avatarColor).withOpacity(0.2),
                        child: Text(
                          user.initials,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(user.avatarColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.fullName,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(user.email,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.onSurface
                                        .withOpacity(0.5))),
                            const SizedBox(height: 6),
                            Text(
                              'Joined ${DateFormat.yMMMd().format(user.createdAt)} · Last login ${DateFormat.yMMMd().format(user.lastLoginAt)}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurface
                                      .withOpacity(0.35)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                const SizedBox(height: 32),
              ],

              // ── System Health ──
              const Text("SYSTEM HEALTH",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.5)),
              const SizedBox(height: 8),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                opacity: 0.1,
                child: healthAsync.when(
                  data: (health) => Column(
                    children: health.entries
                        .map((e) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    e.value
                                        ? Icons.check_circle
                                        : Icons.error,
                                    color: e.value
                                        ? Colors.green
                                        : Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(e.key,
                                      style: const TextStyle(fontSize: 16)),
                                  const Spacer(),
                                  Text(
                                    e.value ? "ONLINE" : "OFFLINE",
                                    style: TextStyle(
                                      color: e.value
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text("System Check Failed: $err",
                      style: const TextStyle(color: Colors.red)),
                ),
              ),

              const SizedBox(height: 32),

              // ── Preferences ──
              const Text("PREFERENCES",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.5)),
              const SizedBox(height: 8),
              GlassContainer(
                padding: const EdgeInsets.all(0),
                opacity: 0.1,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text("Dark Mode"),
                      secondary: const Icon(Icons.dark_mode),
                      value: themeMode == ThemeMode.dark,
                      onChanged: (val) {
                        final newMode =
                            val ? ThemeMode.dark : ThemeMode.light;
                        ref
                            .read(themeModeProvider.notifier)
                            .setTheme(newMode);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text("Demo Mode"),
                      subtitle:
                          const Text("Force successful recognitions"),
                      secondary: const Icon(Icons.play_circle_filled,
                          color: Colors.orange),
                      value: isDemoMode,
                      activeTrackColor: Colors.orange.withOpacity(0.3),
                      onChanged: (val) {
                        ref
                            .read(demoModeProvider.notifier)
                            .toggle(val);
                        ref.invalidate(systemHealthProvider);
                      },
                    ),
                  ],
                ),
              ),

              // ── Support ──
              _SettingsSection(
                title: "Support",
                children: [
                  _SettingsTile(
                    icon: PhosphorIcons.question(
                        PhosphorIconsStyle.regular),
                    title: "Help & FAQ",
                  ),
                  _SettingsTile(
                    icon: PhosphorIcons.shieldCheck(
                        PhosphorIconsStyle.regular),
                    title: "Privacy Policy",
                  ),
                ],
              ),

              // ── Account ──
              if (user != null)
                _SettingsSection(
                  title: "Account",
                  children: [
                    _SettingsTile(
                      icon: PhosphorIcons.signOut(
                          PhosphorIconsStyle.regular),
                      title: "Logout",
                      onTap: () async {
                        await ref
                            .read(authControllerProvider.notifier)
                            .logout();
                        if (context.mounted) context.go('/login');
                      },
                    ),
                    _SettingsTile(
                      icon: PhosphorIcons.trash(
                          PhosphorIconsStyle.regular),
                      title: "Delete Account",
                      isDestructive: true,
                      onTap: () => _confirmDeleteAccount(context, ref),
                    ),
                  ],
                ),

              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                    child: Text("Version 1.0.0",
                        style: TextStyle(
                            color: Colors.grey.withOpacity(0.5)))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
            'This will permanently delete your account and all data. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(authControllerProvider.notifier)
                  .deleteAccount();
              if (context.mounted) context.go('/register');
            },
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFE53935)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(title,
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.6),
                  fontWeight: FontWeight.w600)),
        ),
        GlassContainer(
          opacity: 0.05,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: children
                .map((c) => Column(
                      children: [
                        c,
                        if (c != children.last)
                          Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: Colors.grey.withOpacity(0.1)),
                      ],
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 24),
      ],
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? const Color(0xFFE53935)
        : Theme.of(context).colorScheme.onSurface;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: color.withOpacity(0.4)),
      onTap: onTap,
    );
  }
}

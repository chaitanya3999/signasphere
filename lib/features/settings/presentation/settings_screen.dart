import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets/animated_scale_button.dart';

// Riverpod 3 migration: StateProvider -> Notifier
final demoModeProvider = NotifierProvider<DemoModeNotifier, bool>(DemoModeNotifier.new);

class DemoModeNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle(bool value) => state = value;
}

final systemHealthProvider = FutureProvider<Map<String, bool>>((ref) async {
  // Watch demo mode to re-trigger check
  ref.watch(demoModeProvider); 
  
  final cameraStatus = await Permission.camera.status;
  final micStatus = await Permission.microphone.status;
  // Simulating server connection for demo
  await Future.delayed(const Duration(milliseconds: 500)); 
  
  return {
    "Camera": cameraStatus.isGranted,
    "Microphone": micStatus.isGranted,
    "AI Engine": true, // Always true for demo
  };
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDemoMode = ref.watch(demoModeProvider);
    final healthAsync = ref.watch(systemHealthProvider);

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
              // System Health Card
              const Text("SYSTEM HEALTH", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                opacity: 0.1,
                child: healthAsync.when(
                  data: (health) => Column(
                    children: health.entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            e.value ? Icons.check_circle : Icons.error, 
                            color: e.value ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(e.key, style: const TextStyle(fontSize: 16)),
                          const Spacer(),
                          Text(e.value ? "ONLINE" : "OFFLINE", 
                              style: TextStyle(
                                color: e.value ? Colors.green : Colors.red, 
                                fontWeight: FontWeight.bold,
                                fontSize: 12
                              )
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Text("System Check Failed: $err", style: const TextStyle(color: Colors.red)),
                ),
              ),

              const SizedBox(height: 32),

              // Preferences
              const Text("PREFERENCES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5)),
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
                        final newMode = val ? ThemeMode.dark : ThemeMode.light;
                        ref.read(themeModeProvider.notifier).setTheme(newMode);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text("Demo Mode"),
                      subtitle: const Text("Force successful recognitions"),
                      secondary: const Icon(Icons.play_circle_filled, color: Colors.orange),
                      value: isDemoMode,
                      activeColor: Colors.orange,
                      onChanged: (val) {
                         ref.read(demoModeProvider.notifier).toggle(val);
                         ref.refresh(systemHealthProvider);
                      },
                    ),
                  ],
                ),
              ),

              _SettingsSection(
                title: "Support",
                children: [
                   _SettingsTile(icon: PhosphorIcons.question(PhosphorIconsStyle.regular), title: "Help & FAQ"),
                   _SettingsTile(icon: PhosphorIcons.shieldCheck(PhosphorIconsStyle.regular), title: "Privacy Policy"),
                ],
              ),

               Padding(
                 padding: const EdgeInsets.all(24.0),
                 child: Center(child: Text("Version 1.0.0", style: TextStyle(color: Colors.grey.withOpacity(0.5)))),
               ),
            ],
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
          child: Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.w600)),
        ),
        GlassContainer(
          opacity: 0.05,
          borderRadius: BorderRadius.circular(16),
          child: Column(
             children: children.map((c) => Column(
               children: [
                 c,
                 if (c != children.last) Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.withOpacity(0.1)),
               ],
             )).toList(),
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
  final String? value;
  final Widget? trailing;

  const _SettingsTile({required this.icon, required this.title, this.value, this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
      title: Text(title),
      trailing: trailing ?? (value != null ? Text(value!, style: TextStyle(color: Theme.of(context).colorScheme.primary)) : const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey)),
      onTap: () {},
    );
  }
}

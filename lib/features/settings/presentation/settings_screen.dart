import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_controller.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/glass_container.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark || 
                      (themeMode == ThemeMode.system && MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background
           Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).scaffoldBackgroundColor,
                  Colors.grey.withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          ListView(
            padding: const EdgeInsets.fromLTRB(20, 100, 20, 100),
            children: [
              // Profile Section
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      child: Icon(PhosphorIcons.user(PhosphorIconsStyle.fill), size: 50, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(height: 12),
                    const Text('Alex Doe', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const Text('alex.doe@example.com', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    GlassContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      borderRadius: BorderRadius.circular(20),
                      color: Theme.of(context).colorScheme.primary,
                      opacity: 0.1,
                      child: Text('Edit Profile', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ).animate().scale(curve: Curves.easeOutBack),

              const SizedBox(height: 32),

              _SettingsSection(
                title: "General",
                children: [
                  _SettingsTile(icon: PhosphorIcons.globe(PhosphorIconsStyle.regular), title: "Language", value: "English"),
                  _SettingsTile(icon: PhosphorIcons.handWaving(PhosphorIconsStyle.regular), title: "Sign Language", value: "ASL"),
                ],
              ),
              
              _SettingsSection(
                title: "Appearance",
                children: [
                   _SettingsTile(
                     icon: PhosphorIcons.moon(PhosphorIconsStyle.regular), 
                     title: "Dark Mode", 
                     trailing: Switch(
                       value: isDarkMode, 
                       onChanged: (v) {
                         ref.read(themeModeProvider.notifier).setTheme(v ? ThemeMode.dark : ThemeMode.light);
                       }
                     ),
                   ),
                   _SettingsTile(icon: PhosphorIcons.textT(PhosphorIconsStyle.regular), title: "Text Size", value: "Medium"),
                ],
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

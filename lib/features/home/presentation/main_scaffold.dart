import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/widgets/glass_container.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Important for glass effect behind nav bar
      body: child,
      bottomNavigationBar: _GlassBottomNavBar(),
    );
  }
}

class _GlassBottomNavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        height: 70,
        child: GlassContainer(
          borderRadius: BorderRadius.circular(35),
          blur: 20,
          opacity: 0.1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavBarItem(
                icon: PhosphorIcons.house(PhosphorIconsStyle.fill),
                label: 'Home',
                isSelected: GoRouterState.of(context).uri.toString() == '/home',
                onTap: () => context.go('/home'),
              ),
              _NavBarItem(
                icon: PhosphorIcons.handWaving(PhosphorIconsStyle.regular),
                label: 'Sign',
                isSelected: false, // TODO: Update logic when routes exist
                onTap: () {},
              ),
              _NavBarItem(
                icon: PhosphorIcons.robot(PhosphorIconsStyle.regular),
                label: 'Avatar',
                isSelected: false,
                onTap: () {},
              ),
              _NavBarItem(
                icon: PhosphorIcons.chatCircleDots(PhosphorIconsStyle.regular),
                label: 'Chat',
                isSelected: false,
                onTap: () {},
              ),
              _NavBarItem(
                icon: PhosphorIcons.graduationCap(PhosphorIconsStyle.regular),
                label: 'Learn',
                isSelected: false,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected 
        ? Theme.of(context).colorScheme.primary 
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

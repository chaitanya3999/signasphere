import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/animated_scale_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Add bottom padding to avoid overlap with floating nav bar
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 100),
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good Morning,',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
                Text(
                  'Alex', // TODO: Replace with dynamic user name
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => context.push('/settings'),
              child: GlassContainer(
                width: 50,
                height: 50,
                borderRadius: BorderRadius.circular(15),
                opacity: 0.1,
                child: const Icon(Icons.settings_outlined), // Changed to settings icon
              ),
            ),
          ],
        ).animate().fadeIn().moveY(begin: -20, end: 0),

        const SizedBox(height: 24),

        // Hero System Status Card
        GlassContainer(
          height: 180,
          opacity: 0.15,
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.4),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    PhosphorIcons.broadcast(PhosphorIconsStyle.fill),
                    color: Colors.white,
                    size: 32,
                  ),
                  GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.green,
                    opacity: 0.2,
                    child: const Text(
                      'System Online',
                      style: TextStyle(
                        color: Colors.greenAccent, 
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Services Ready',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Camera • Sign Recognition • Avatar',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().scale(delay: 200.ms),

        const SizedBox(height: 32),

        Text(
          'Start Communicating',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ).animate().fadeIn(delay: 400.ms),

        const SizedBox(height: 16),

        // Action Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
          children: [
            _ActionTile(
              title: 'Live Sign\nTranslator',
              icon: PhosphorIcons.handWaving(PhosphorIconsStyle.fill),
              color: Theme.of(context).colorScheme.primary,
              delay: 500,
              onTap: () => context.push('/live-sign'),
            ),
            _ActionTile(
              title: 'Text to\nAvatar',
              icon: PhosphorIcons.robot(PhosphorIconsStyle.fill),
              color: Theme.of(context).colorScheme.secondary,
              delay: 600,
              onTap: () => context.push('/avatar'),
            ),
            _ActionTile(
              title: 'Conversation\nMode',
              icon: PhosphorIcons.chatCircleDots(PhosphorIconsStyle.fill),
              color: Colors.orangeAccent,
              delay: 700,
              isWide: true, // Not used in grid but if we want flow layout
              onTap: () => context.push('/conversation'),
            ),
             _ActionTile(
              title: 'Learn\nSigns',
              icon: PhosphorIcons.graduationCap(PhosphorIconsStyle.fill),
              color: Colors.pinkAccent,
              delay: 800,
              onTap: () => context.push('/learn'),
            ),
          ],
        ),

        const SizedBox(height: 32),

        Text(
          'Quick Modes',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ).animate().fadeIn(delay: 900.ms),

        const SizedBox(height: 16),

        // Quick Domain Modes
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _QuickModeCard(
                label: 'Hospital',
                icon: PhosphorIcons.firstAid(PhosphorIconsStyle.regular),
                delay: 1000,
              ),
              const SizedBox(width: 16),
              _QuickModeCard(
                label: 'Classroom',
                icon: PhosphorIcons.chalkboardTeacher(PhosphorIconsStyle.regular),
                delay: 1100,
              ),
              const SizedBox(width: 16),
              _QuickModeCard(
                label: 'Emergency',
                icon: PhosphorIcons.siren(PhosphorIconsStyle.regular),
                delay: 1200,
              ),
            ],
          ),
        ),
      ],
    );
  }
}



class _ActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int delay;
  final VoidCallback onTap;
  final bool isWide;

  const _ActionTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.delay,
    required this.onTap,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScaleButton(
      onPressed: onTap,
      child: GlassContainer(
        opacity: 0.05,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                icon,
                size: 100,
                color: color.withOpacity(0.1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GlassContainer(
                    width: 48,
                    height: 48,
                    borderRadius: BorderRadius.circular(16),
                    color: color,
                    opacity: 0.2,
                    child: Icon(icon, color: color, size: 24),
                  ),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.2, end: 0);
  }
}

class _QuickModeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final int delay;

  const _QuickModeCard({
    required this.label,
    required this.icon,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      width: 100,
      borderRadius: BorderRadius.circular(20),
      opacity: 0.05,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).scale();
  }
}

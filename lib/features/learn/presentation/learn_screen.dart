import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/glass_container.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        title: const Text('Learn Signs'),
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
                  Colors.pinkAccent.withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 100, 20, 100),
            children: [
              // Statistics Header
              GlassContainer(
                padding: const EdgeInsets.all(20),
                opacity: 0.1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(label: 'Streak', value: '3 Days', icon: Icons.local_fire_department, color: Colors.orange),
                    _StatItem(label: 'XP', value: '450', icon: Icons.star, color: Colors.yellow),
                    _StatItem(label: 'Accuracy', value: '85%', icon: Icons.track_changes, color: Colors.green),
                  ],
                ),
              ).animate().slideY(begin: -0.2, end: 0),

              const SizedBox(height: 24),

              const Text('Modules', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              _ModuleCard(
                title: "Basics: Alphabet",
                subtitle: "Learn A-Z handshapes",
                progress: 0.8,
                color: Colors.purpleAccent,
                icon: PhosphorIcons.textAa(PhosphorIconsStyle.fill),
                delay: 200,
              ),
              const SizedBox(height: 16),
              _ModuleCard(
                title: "Greetings",
                subtitle: "Hello, Goodbye, Thank you",
                progress: 0.3,
                color: Colors.blueAccent,
                icon: PhosphorIcons.handGrabbing(PhosphorIconsStyle.fill),
                delay: 300,
              ),
              const SizedBox(height: 16),
               _ModuleCard(
                title: "Emergency Signs",
                subtitle: "Help, Doctor, Pain",
                progress: 0.0,
                color: Colors.redAccent,
                icon: PhosphorIcons.siren(PhosphorIconsStyle.fill),
                delay: 400,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double progress;
  final Color color;
  final IconData icon;
  final int delay;

  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.color,
    required this.icon,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      height: 100,
      opacity: 0.05,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.play_circle_fill, color: color.withOpacity(0.5), size: 32),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideX();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/animated_scale_button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../user_tracking/controllers/usage_controller.dart';
import '../../user_tracking/models/usage_event.dart';
import '../../emergency/controllers/emergency_controller.dart';
import '../../../core/services/sound_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _tracked = false;

  Future<void> _launchDialer(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 22) return 'Good Evening';
    return 'Good Night';
  }

  void _showUserMenu(BuildContext context, String name, String email) {
    final colorScheme = Theme.of(context).colorScheme;
    final initials = name.trim().split(' ').length >= 2
        ? '${name.trim().split(' ').first[0]}${name.trim().split(' ').last[0]}'.toUpperCase()
        : name.isNotEmpty
            ? name[0].toUpperCase()
            : '?';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: colorScheme.surface.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: colorScheme.primary.withOpacity(0.2))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // User Info
            CircleAvatar(
              radius: 32,
              backgroundColor: colorScheme.primary.withOpacity(0.15),
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(email,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.5),
                    )),
            const SizedBox(height: 24),

            // Menu Items
            _MenuButton(
              icon: PhosphorIcons.gear(PhosphorIconsStyle.regular),
              label: 'Settings',
              onTap: () {
                Navigator.of(ctx).pop();
                context.push('/settings');
              },
            ),
            const SizedBox(height: 8),
            _MenuButton(
              icon: PhosphorIcons.signOut(PhosphorIconsStyle.regular),
              label: 'Logout',
              isDestructive: true,
              onTap: () async {
                Navigator.of(ctx).pop();
                await ref.read(authControllerProvider.notifier).logout();
                if (mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final firstName = user?.firstName ?? 'User';
    final greeting = _getGreeting();
    final colorScheme = Theme.of(context).colorScheme;

    // Track app opened once
    if (!_tracked) {
      _tracked = true;
      ref.read(usageControllerProvider).trackEvent(UsageEventType.appOpened);
    }

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
                  '$greeting,',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
                Text(
                  firstName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                if (user != null) {
                  _showUserMenu(context, user.fullName, user.email);
                }
              },
              child: CircleAvatar(
                radius: 25,
                backgroundColor: user != null
                    ? Color(user.avatarColor).withOpacity(0.2)
                    : colorScheme.primary.withOpacity(0.15),
                child: Text(
                  user?.initials ?? '?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: user != null
                        ? Color(user.avatarColor)
                        : colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ).animate().fadeIn().moveY(begin: -20, end: 0),

        const SizedBox(height: 24),

        // Hero Card
        GlassContainer(
          height: 180,
          opacity: 0.15,
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withOpacity(0.4),
              colorScheme.secondary.withOpacity(0.1),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How can I help you today?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap a feature below to get started',
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

        // Quick Emergency Modes
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _QuickModeCard(
                label: 'Emergency',
                icon: PhosphorIcons.siren(PhosphorIconsStyle.fill),
                color: const Color(0xFFE53935),
                delay: 1000,
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(soundServiceProvider).playTap();
                  context.push('/emergency');
                },
              ),
              const SizedBox(width: 16),
              _QuickModeCard(
                label: 'Contact Parent',
                icon: PhosphorIcons.phoneCall(PhosphorIconsStyle.fill),
                color: const Color(0xFF1E88E5),
                delay: 1100,
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(soundServiceProvider).playTap();
                  _showContactParentSheet(context, ref);
                },
              ),
              const SizedBox(width: 16),
              _QuickModeCard(
                label: 'Help Sound',
                icon: PhosphorIcons.speakerHigh(PhosphorIconsStyle.fill),
                color: const Color(0xFFFF9800),
                delay: 1200,
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(soundServiceProvider).playTap();
                  _showHelpSoundPopup(context, ref);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showContactParentSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Contact Parent',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(PhosphorIcons.chatText(PhosphorIconsStyle.fill)),
              label: const Text('SMS + Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              onPressed: () {
                ref.read(soundServiceProvider).playTap();
                ref.read(emergencyControllerProvider.notifier).sendSMS("Reaching out to parent.");
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: Icon(PhosphorIcons.whatsappLogo(PhosphorIconsStyle.fill)),
              label: const Text('WhatsApp + Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              onPressed: () {
                ref.read(soundServiceProvider).playTap();
                ref.read(emergencyControllerProvider.notifier).sendWhatsApp("Reaching out to parent.");
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: Icon(PhosphorIcons.phoneCall(PhosphorIconsStyle.fill)),
              label: const Text('Call Parent'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              onPressed: () {
                ref.read(soundServiceProvider).playTap();
                ref.read(emergencyControllerProvider.notifier).callParent();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showHelpSoundPopup(BuildContext context, WidgetRef ref) {
     // Start alarm immediately
     ref.read(emergencyControllerProvider.notifier).toggleAlarm();
     
     showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red[900],
        title: const Text("LOUD SOUND PLAYING", style: TextStyle(color: Colors.white)),
        content: const Icon(Icons.volume_up_rounded, size: 80, color: Colors.white),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red),
              onPressed: () {
                ref.read(emergencyControllerProvider.notifier).stopAlarm();
                Navigator.pop(context);
              },
              child: const Text("STOP SOUND", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
     ).then((_) {
       ref.read(emergencyControllerProvider.notifier).stopAlarm();
     });
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? const Color(0xFFE53935)
        : Theme.of(context).colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: (isDestructive
                  ? const Color(0xFFE53935)
                  : Theme.of(context).colorScheme.onSurface)
              .withOpacity(0.05),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                )),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int delay;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.delay,
    required this.onTap,
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

class _QuickModeCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int delay;
  final VoidCallback onTap;

  const _QuickModeCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.delay,
    required this.onTap,
  });

  @override
  State<_QuickModeCard> createState() => _QuickModeCardState();
}

class _QuickModeCardState extends State<_QuickModeCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: GlassContainer(
          width: 100,
          borderRadius: BorderRadius.circular(20),
          opacity: 0.05,
          border: Border.all(
            color: widget.color.withOpacity(0.3),
            width: 1,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity(0.12),
                ),
                child: Icon(widget.icon, size: 20, color: widget.color),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.color,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: widget.delay.ms).scale();
  }
}

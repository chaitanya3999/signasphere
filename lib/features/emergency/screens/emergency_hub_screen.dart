import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/widgets/glass_app_bar.dart';
import '../../../core/widgets/glass_container.dart';
import '../controllers/emergency_controller.dart';
import '../../emergency/services/emergency_contacts_service.dart';
import 'emergency_contacts_screen.dart';

class EmergencyHubScreen extends ConsumerWidget {
  const EmergencyHubScreen({super.key});

  void _showConfirmationDialog(BuildContext context, WidgetRef ref, String message) {
    // Play warning sound immediately
    ref.read(emergencyControllerProvider.notifier).playWarning();

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.9),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return _EmergencyConfirmationOverlay(
          message: message,
          onConfirm: () {
             ref.read(emergencyControllerProvider.notifier).sendSMS(message);
             // Also send WA
             ref.read(emergencyControllerProvider.notifier).sendWhatsApp(message);
             // And alert sound? Requirement says "Play warning sound instantly", "On Confirm: Execute action". 
             // "Play alarm sound" is listed as an action in prompt but maybe better to keep alarm manual or auto?
             // Prompt: "3. Provide actions: ... Play alarm sound"
             // I'll add buttons in the overlay for these.
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim1.value),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(emergencyControllerProvider.notifier);
    final isAlarmPlaying = ref.watch(emergencyControllerProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'Emergency 🚨',
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.gear(PhosphorIconsStyle.fill), color: Colors.white),
            tooltip: 'Manage Contacts',
            onPressed: () {
              // Navigate to contacts screen
              // Assuming route is /emergency/contacts or just push widget
              // If GoRouter: context.push('/emergency/contacts');
              // If direct nav:
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2B0000), 
              Theme.of(context).colorScheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              Text(
                'EMERGENCY QUICK ACTIONS',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
              ).animate().fadeIn(),

              const SizedBox(height: 16),

              // GRID
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _EmergencyGridButton(
                    title: 'I AM HURT',
                    icon: PhosphorIcons.firstAid(PhosphorIconsStyle.fill),
                    color: const Color(0xFFE53935), 
                    onTap: () => _showConfirmationDialog(context, ref, "I AM HURT"),
                    delay: 100,
                  ),
                  _EmergencyGridButton(
                    title: 'I AM LOST',
                    icon: PhosphorIcons.mapPin(PhosphorIconsStyle.fill),
                    color: const Color(0xFFFB8C00), 
                    onTap: () => _showConfirmationDialog(context, ref, "I AM LOST"),
                    delay: 150,
                  ),
                  _EmergencyGridButton(
                    title: 'I FEEL UNSAFE',
                    icon: PhosphorIcons.shieldWarning(PhosphorIconsStyle.fill),
                    color: const Color(0xFF8E24AA), 
                    onTap: () => _showConfirmationDialog(context, ref, "I FEEL UNSAFE"),
                    delay: 200,
                  ),
                  _EmergencyGridButton(
                    title: 'FIRE / SMOKE',
                    icon: PhosphorIcons.fire(PhosphorIconsStyle.fill),
                    color: const Color(0xFFD84315), 
                    onTap: () => _showConfirmationDialog(context, ref, "FIRE DETECTED"),
                    delay: 250,
                  ),
                  _EmergencyGridButton(
                    title: 'SOMEONE IS NOT NICE',
                    icon: PhosphorIcons.userMinus(PhosphorIconsStyle.fill),
                    color: const Color(0xFF546E7A), 
                    onTap: () => _showConfirmationDialog(context, ref, "SOMEONE IS NOT NICE"),
                    delay: 300,
                  ),
                  _EmergencyGridButton(
                    title: 'I NEED HELP NOW',
                    icon: PhosphorIcons.warning(PhosphorIconsStyle.fill),
                    color: const Color(0xFFC62828), 
                    onTap: () => _showConfirmationDialog(context, ref, "I NEED HELP NOW"),
                    delay: 350,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              Text(
                'ALERT MY FAMILY',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _FamilyAlertButton(
                      icon: PhosphorIcons.chatText(PhosphorIconsStyle.fill),
                      label: 'SMS + Location',
                      color: const Color(0xFF4CAF50), 
                      onTap: () {
                        controller.playTap();
                        controller.sendSMS("I NEED HELP!");
                      },
                      delay: 450,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FamilyAlertButton(
                      icon: PhosphorIcons.whatsappLogo(PhosphorIconsStyle.fill),
                      label: 'WhatsApp',
                      color: const Color(0xFF25D366), 
                      onTap: () {
                        controller.playTap();
                        controller.sendWhatsApp("I NEED HELP!");
                      },
                      delay: 500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _FamilyAlertButton(
                icon: PhosphorIcons.phoneCall(PhosphorIconsStyle.fill),
                label: 'Call Parent',
                color: const Color(0xFF1976D2), 
                onTap: () {
                  controller.playTap();
                  controller.callParent();
                },
                delay: 550,
              ),

              const SizedBox(height: 32),

              Text(
                'ALARM',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
              ).animate().fadeIn(delay: 600.ms),

              const SizedBox(height: 16),

              GestureDetector(
                onTap: () {
                  controller.playTap();
                  controller.toggleAlarm();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 80,
                  decoration: BoxDecoration(
                    color: isAlarmPlaying 
                        ? const Color(0xFFD50000) 
                        : Theme.of(context).colorScheme.surface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isAlarmPlaying 
                          ? const Color(0xFFFF5252) 
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                      width: isAlarmPlaying ? 3 : 1,
                    ),
                    boxShadow: isAlarmPlaying 
                        ? [
                            BoxShadow(
                              color: const Color(0xFFD50000).withOpacity(0.6),
                              blurRadius: 30,
                              spreadRadius: 5,
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isAlarmPlaying 
                            ? PhosphorIcons.speakerHigh(PhosphorIconsStyle.fill) 
                            : PhosphorIcons.speakerSlash(PhosphorIconsStyle.regular),
                        color: isAlarmPlaying ? Colors.white : Colors.white70,
                        size: 32,
                      ).animate(target: isAlarmPlaying ? 1 : 0).shake(hz: 4, offset: const Offset(2, 0)),
                      const SizedBox(width: 16),
                      Text(
                        isAlarmPlaying ? 'STOP ALARM' : 'PLAY LOUD HELP SOUND',
                        style: TextStyle(
                          color: isAlarmPlaying ? Colors.white : Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 650.ms).scale(),

              const SizedBox(height: 80), 
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyGridButton extends ConsumerWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int delay;

  const _EmergencyGridButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.delay,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(emergencyControllerProvider.notifier).playTap();
        onTap();
      },
      child: GlassContainer(
        opacity: 0.1,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1.5,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color, 
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).scale(duration: 400.ms, curve: Curves.easeOutBack);
  }
}

class _FamilyAlertButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int delay;

  const _FamilyAlertButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: GlassContainer(
        height: 60,
        opacity: 0.1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.1, end: 0);
  }
}

class _EmergencyConfirmationOverlay extends ConsumerWidget {
  final String message;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _EmergencyConfirmationOverlay({
    required this.message,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(emergencyControllerProvider.notifier);
    
    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF212121),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.redAccent, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withOpacity(0.3),
                blurRadius: 50,
                spreadRadius: 10,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 60, color: Colors.orangeAccent)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2)),
              const SizedBox(height: 24),
              Text(
                "Sending Alert:",
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              
              // Actions
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  icon: Icon(PhosphorIcons.chatText(PhosphorIconsStyle.fill)),
                  label: const Text("SMS + Location"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  onPressed: () {
                    controller.playTap();
                    controller.sendSMS(message);
                    Navigator.pop(context); // Close overlay after sending
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  icon: Icon(PhosphorIcons.whatsappLogo(PhosphorIconsStyle.fill)),
                  label: const Text("WhatsApp + Location"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () {
                    controller.playTap();
                    controller.sendWhatsApp(message);
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  icon: Icon(PhosphorIcons.speakerHigh(PhosphorIconsStyle.fill)),
                  label: const Text("PLAY LOUD ALARM"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800]),
                  onPressed: () {
                    controller.playTap();
                    controller.stopAlarm().then((_) => controller.toggleAlarm());
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                   controller.playTap();
                   onCancel();
                },
                child: const Text("CANCEL", style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

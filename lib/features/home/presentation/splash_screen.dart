import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/glass_container.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          // Center Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GlassContainer(
                  width: 120,
                  height: 120,
                  borderRadius: BorderRadius.circular(30),
                  blur: 20,
                  opacity: 0.2,
                  child: Center(
                    child: Icon(
                      Icons.accessibility_new_rounded,
                      size: 60,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ).animate()
                  .scale(duration: 600.ms, curve: Curves.easeOutBack)
                  .fade(duration: 400.ms),
                  
                const SizedBox(height: 24),
                
                Text(
                  'Signasphere',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ).animate()
                  .fadeIn(delay: 400.ms, duration: 600.ms)
                  .moveY(begin: 20, end: 0),
                  
                const SizedBox(height: 8),
                
                Text(
                  'Bridging Worlds',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                  ),
                ).animate()
                  .fadeIn(delay: 600.ms, duration: 600.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

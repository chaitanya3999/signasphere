import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/widgets/glass_container.dart';
import 'navbar_controller.dart';

class MainScaffold extends ConsumerStatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold>
    with TickerProviderStateMixin {
  // Navbar slide animation
  late final AnimationController _navAnimController;
  late final Animation<Offset> _navSlideAnimation;
  late final Animation<double> _navFadeAnimation;

  // Edge handle animation
  late final AnimationController _handleAnimController;
  late final Animation<Offset> _handleSlideAnimation;
  late final Animation<double> _handleFadeAnimation;

  @override
  void initState() {
    super.initState();

    // --- Navbar animations ---
    _navAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _navSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 1.5),
    ).animate(
      CurvedAnimation(parent: _navAnimController, curve: Curves.easeInOutCubic),
    );
    _navFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _navAnimController, curve: Curves.easeInOut),
    );

    // --- Edge handle animations ---
    _handleAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _handleSlideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0), // Start off-screen right
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _handleAnimController, curve: Curves.easeOutCubic),
    );
    _handleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _handleAnimController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _navAnimController.dispose();
    _handleAnimController.dispose();
    super.dispose();
  }

  void _syncAnimations(bool isVisible) {
    if (isVisible) {
      _navAnimController.reverse();
      _handleAnimController.reverse();
    } else {
      _navAnimController.forward();
      // Delay the handle appearance so navbar slides away first
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _handleAnimController.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNavBarVisible = ref.watch(navBarVisibilityProvider);

    // Sync animations with state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncAnimations(isNavBarVisible);
    });

    final screenHeight = MediaQuery.of(context).size.height;
    final rightPadding = MediaQuery.of(context).padding.right;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Main content
          widget.child,

          // 1. Bottom Navbar (Slide down to hide)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SlideTransition(
              position: _navSlideAnimation,
              child: FadeTransition(
                opacity: _navFadeAnimation,
                child: GestureDetector(
                  onVerticalDragEnd: (details) {
                    if (details.primaryVelocity != null &&
                        details.primaryVelocity! > 200) {
                      ref.read(navBarVisibilityProvider.notifier).hide();
                      HapticFeedback.lightImpact();
                    }
                  },
                  child: const _GlassBottomNavBar(),
                ),
              ),
            ),
          ),

          // 2. Samsung Edge Panel Handle (right side, visible when navbar hidden)
          Positioned(
            right: rightPadding, // Respect safe area
            top: screenHeight * 0.62,  // ~65% down the screen
            child: IgnorePointer(
              ignoring: isNavBarVisible,
              child: SlideTransition(
                position: _handleSlideAnimation,
                child: FadeTransition(
                  opacity: _handleFadeAnimation,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      ref.read(navBarVisibilityProvider.notifier).show();
                      HapticFeedback.lightImpact();
                    },
                    onHorizontalDragEnd: (details) {
                      // Swipe LEFT to restore navbar
                      if (details.primaryVelocity != null &&
                          details.primaryVelocity! < -100) {
                        ref.read(navBarVisibilityProvider.notifier).show();
                        HapticFeedback.lightImpact();
                      }
                    },
                    child: const _EdgeHandle(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Samsung Edge Panel Handle ───────────────────────────────────────────────

class _EdgeHandle extends StatelessWidget {
  const _EdgeHandle();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      // Outer container provides the 44px min touch target
      width: 44,
      height: 56,
      alignment: Alignment.centerRight,
      child: ClipRRect(
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: 22,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
              color: (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.12 : 0.06),
              border: Border(
                left: BorderSide(
                  color: primary.withOpacity(0.35),
                  width: 1.5,
                ),
                top: BorderSide(
                  color: primary.withOpacity(0.2),
                  width: 0.5,
                ),
                bottom: BorderSide(
                  color: primary.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(0.12),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(-2, 0),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(-1, 0),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                PhosphorIcons.caretLeft(PhosphorIconsStyle.bold),
                size: 12,
                color: primary.withOpacity(0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Glass Bottom NavBar ─────────────────────────────────────────────────────

class _GlassBottomNavBar extends ConsumerWidget {
  const _GlassBottomNavBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUri = GoRouterState.of(context).uri.toString();

    return Container(
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
              icon: PhosphorIcons.house(currentUri == '/home'
                  ? PhosphorIconsStyle.fill
                  : PhosphorIconsStyle.regular),
              label: 'Home',
              isSelected: currentUri == '/home',
              onTap: () => context.go('/home'),
            ),
            _NavBarItem(
              icon: PhosphorIcons.handWaving(currentUri == '/live-sign'
                  ? PhosphorIconsStyle.fill
                  : PhosphorIconsStyle.regular),
              label: 'Sign',
              isSelected: currentUri == '/live-sign',
              onTap: () => context.go('/live-sign'),
            ),
            _NavBarItem(
              icon: PhosphorIcons.robot(currentUri == '/avatar'
                  ? PhosphorIconsStyle.fill
                  : PhosphorIconsStyle.regular),
              label: 'Avatar',
              isSelected: currentUri == '/avatar',
              onTap: () => context.go('/avatar'),
            ),
            _NavBarItem(
              icon: PhosphorIcons.chatCircleDots(currentUri == '/conversation'
                  ? PhosphorIconsStyle.fill
                  : PhosphorIconsStyle.regular),
              label: 'Chat',
              isSelected: currentUri == '/conversation',
              onTap: () => context.go('/conversation'),
            ),
            _NavBarItem(
              icon: PhosphorIcons.graduationCap(currentUri == '/learn'
                  ? PhosphorIconsStyle.fill
                  : PhosphorIconsStyle.regular),
              label: 'Learn',
              isSelected: currentUri == '/learn',
              onTap: () => context.go('/learn'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── NavBar Item ─────────────────────────────────────────────────────────────

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

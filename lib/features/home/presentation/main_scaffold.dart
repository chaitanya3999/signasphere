import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/widgets/glass_container.dart';

class MainScaffold extends StatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> with SingleTickerProviderStateMixin {
  bool _isNavBarVisible = true;
  late final AnimationController _animController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 1.5), // slide fully below screen
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOutCubic));
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleNavBar() {
    setState(() {
      _isNavBarVisible = !_isNavBarVisible;
      if (_isNavBarVisible) {
        _animController.reverse();
      } else {
        _animController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Nav bar with slide animation
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: GestureDetector(
                onVerticalDragEnd: (details) {
                  // Swipe down to hide
                  if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
                    _toggleNavBar();
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Small drag handle above the nav bar
                    GestureDetector(
                      onTap: _toggleNavBar,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        width: 36,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    _GlassBottomNavBar(),
                  ],
                ),
              ),
            ),
          ),

          // When hidden: show a small pull-up pill to bring it back
          if (!_isNavBarVisible)
            Positioned(
              bottom: 8,
              child: GestureDetector(
                onTap: _toggleNavBar,
                onVerticalDragEnd: (details) {
                  // Swipe up to show
                  if (details.primaryVelocity != null && details.primaryVelocity! < -50) {
                    _toggleNavBar();
                  }
                },
                child: AnimatedOpacity(
                  opacity: _isNavBarVisible ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 400),
                  child: Container(
                    width: 48,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
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

class _GlassBottomNavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
              icon: PhosphorIcons.house(currentUri == '/home' ? PhosphorIconsStyle.fill : PhosphorIconsStyle.regular),
              label: 'Home',
              isSelected: currentUri == '/home',
              onTap: () => context.go('/home'),
            ),
            _NavBarItem(
              icon: PhosphorIcons.handWaving(currentUri == '/live-sign' ? PhosphorIconsStyle.fill : PhosphorIconsStyle.regular),
              label: 'Sign',
              isSelected: currentUri == '/live-sign',
              onTap: () => context.go('/live-sign'),
            ),
            _NavBarItem(
              icon: PhosphorIcons.robot(currentUri == '/avatar' ? PhosphorIconsStyle.fill : PhosphorIconsStyle.regular),
              label: 'Avatar',
              isSelected: currentUri == '/avatar',
              onTap: () => context.go('/avatar'),
            ),
            _NavBarItem(
              icon: PhosphorIcons.chatCircleDots(currentUri == '/conversation' ? PhosphorIconsStyle.fill : PhosphorIconsStyle.regular),
              label: 'Chat',
              isSelected: currentUri == '/conversation',
              onTap: () => context.go('/conversation'),
            ),
            _NavBarItem(
              icon: PhosphorIcons.graduationCap(currentUri == '/learn' ? PhosphorIconsStyle.fill : PhosphorIconsStyle.regular),
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

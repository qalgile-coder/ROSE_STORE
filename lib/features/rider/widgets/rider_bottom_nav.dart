import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';

class RiderBottomNav extends StatelessWidget {
  final int currentIndex;
  const RiderBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final navBgColor = AppColors.premiumDarkSurface.withValues(alpha: 0.9);
    final activeColor = AppColors.rider;
    final inactiveColor = colorScheme.onSurface.withValues(alpha: 0.3);

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 30),
      height: 76,
      decoration: BoxDecoration(
        color: navBgColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: AppColors.premiumDarkDivider.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _RiderNavItem(
                icon: Icons.grid_view_rounded, 
                label: 'Status', 
                isActive: currentIndex == 0,
                onTap: () => context.go('/rider'),
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
              _RiderNavItem(
                icon: Icons.assignment_rounded, 
                label: 'Active', 
                isActive: currentIndex == 1,
                onTap: () => context.go('/rider/active-tasks'),
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
              _RiderNavItem(
                icon: Icons.history_rounded, 
                label: 'History', 
                isActive: currentIndex == 2,
                onTap: () => context.go('/rider/history'),
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
              _RiderNavItem(
                icon: Icons.person_rounded, 
                label: 'Account', 
                isActive: currentIndex == 3,
                onTap: () => context.go('/rider/profile'),
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RiderNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;
  final Color inactiveColor;

  const _RiderNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.symmetric(horizontal: isActive ? 12 : 8, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: isActive ? activeColor : inactiveColor,
              size: 24,
            ),
          ),
          if (!isActive) ...[
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: inactiveColor,
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';

class VendorBottomNav extends StatelessWidget {
  final int currentIndex;
  const VendorBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    
    final navBgColor = isLight ? Colors.white.withOpacity(0.9) : AppColors.premiumDarkSurface.withOpacity(0.9);
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = isLight ? AppColors.lightTextHint : AppColors.premiumDarkTextSecondary.withOpacity(0.5);

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 30),
      height: 76,
      decoration: BoxDecoration(
        color: navBgColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: isLight ? Colors.black.withOpacity(0.08) : Colors.black.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: isLight ? AppColors.lightBorder : AppColors.premiumDarkDivider.withOpacity(0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _VendorNavItem(
                icon: Icons.grid_view_rounded, 
                label: 'Dashboard', 
                isActive: currentIndex == 0,
                onTap: () => context.go('/vendor'),
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
              _VendorNavItem(
                icon: Icons.receipt_long_rounded, 
                label: 'Orders', 
                isActive: currentIndex == 1,
                onTap: () => context.go('/vendor/orders'),
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
              _VendorNavItem(
                icon: Icons.layers_rounded, 
                label: 'Stock', 
                isActive: currentIndex == 2,
                onTap: () => context.go('/vendor/products'),
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
              _VendorNavItem(
                icon: Icons.store_rounded, 
                label: 'Profile', 
                isActive: currentIndex == 3,
                onTap: () => context.go('/vendor/profile'),
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

class _VendorNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;
  final Color inactiveColor;

  const _VendorNavItem({
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
              color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
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

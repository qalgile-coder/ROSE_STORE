import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../core/localization.dart';

class CustomerBottomNav extends ConsumerWidget {
  final int currentIndex;
  const CustomerBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    
    final navBgColor = isLight ? Colors.white.withOpacity(0.9) : AppColors.premiumDarkSurface.withOpacity(0.9);
    final activeColor = isLight ? AppColors.lightPrimary : AppColors.premiumDarkPrimary;
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
              _CustomerNavItem(
                icon: Icons.grid_view_rounded, 
                label: 'home'.tr(ref), 
                isActive: currentIndex == 0,
                onTap: () => context.go('/customer'),
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
              _CustomerNavItem(
                icon: Icons.search_rounded, 
                label: 'search'.tr(ref), 
                isActive: currentIndex == 1,
                onTap: () => context.go('/customer/search'),
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
              _CustomerNavItem(
                icon: Icons.shopping_bag_rounded, 
                label: 'cart'.tr(ref), 
                isActive: currentIndex == 2,
                onTap: () => context.go('/customer/cart'),
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
              _CustomerNavItem(
                icon: Icons.receipt_long_rounded, 
                label: 'orders'.tr(ref), 
                isActive: currentIndex == 3,
                onTap: () => context.go('/customer/orders'),
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
              _CustomerNavItem(
                icon: Icons.person_rounded, 
                label: 'account'.tr(ref),
                isActive: currentIndex == 4,
                onTap: () => context.go('/customer/profile'),
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

class _CustomerNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;
  final Color inactiveColor;

  const _CustomerNavItem({
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    color: inactiveColor,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

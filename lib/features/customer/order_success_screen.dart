import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';

class OrderSuccessScreen extends StatelessWidget {
  final String orderId;
  const OrderSuccessScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Premium Success Icon
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(color: AppColors.success.withOpacity(0.05), shape: BoxShape.circle),
                  ),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), shape: BoxShape.circle),
                  ),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                    child: Icon(Icons.check_rounded, size: 40, color: isLight ? Colors.white : AppColors.background),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              Text(
                'Order Confirmed!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: colorScheme.onBackground, letterSpacing: -1),
              ),
              const SizedBox(height: 12),
              Text(
                'Your payment was successful. The store is now preparing your order.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.w500, height: 1.5),
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: colorScheme.surface, 
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20)] : [BoxShadow(color: colorScheme.primary.withOpacity(0.05), blurRadius: 20)],
                  border: isLight ? Border.all(color: colorScheme.outline.withOpacity(0.05)) : Border.all(color: colorScheme.outline.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Text('ORDER REFERENCE', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2)),
                    const SizedBox(height: 6),
                    Text('#${orderId.toUpperCase()}', style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              ElevatedButton(
                onPressed: () => context.go('/customer'),
                child: const Text('BACK TO HOME'),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => context.push('/customer/order-details/$orderId'),
                icon: Icon(Icons.location_on_rounded, size: 18, color: colorScheme.primary),
                label: const Text('TRACK DELIVERY'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary, 
                  side: BorderSide(color: colorScheme.primary, width: 1.5)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/localization.dart';
import '../../theme/app_colors.dart';
import './widgets/customer_bottom_nav.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
                elevation: 0,
                scrolledUnderElevation: 0,
                centerTitle: false,
                title: Text(
                  'my_cart'.tr(ref), 
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: colorScheme.onBackground, letterSpacing: -0.5)
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(color: Colors.transparent),
                  ),
                ),
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: colorScheme.onBackground),
                  onPressed: () => context.go('/customer'),
                ),
                actions: [
                  if (cart.itemCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: TextButton(
                        onPressed: () => _showClearCartDialog(context, ref),
                        child: Text(
                          'clear'.tr(ref).toUpperCase(), 
                          style: TextStyle(color: AppColors.error.withValues(alpha: 0.7), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)
                        ),
                      ),
                    ),
                ],
              ),
              if (cart.itemCount == 0)
                SliverFillRemaining(child: _buildEmptyCart(context, ref))
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 280),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = cart.items.values.toList()[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _CartItemTile(item: item),
                        );
                      },
                      childCount: cart.items.length,
                    ),
                  ),
                ),
            ],
          ),
          
          if (cart.itemCount > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildFloatingBillSummary(context, ref, cart),
            ),

          if (cart.itemCount == 0)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomerBottomNav(currentIndex: 2),
            ),
        ],
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, WidgetRef ref) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isLight ? Colors.white : AppColors.dialog,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('clear'.tr(ref) + '?', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w800)),
        content: Text('This will remove all premium items from your bag.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr(ref).toUpperCase(), style: const TextStyle(color: AppColors.textHint))),
          TextButton(
            onPressed: () { ref.read(cartProvider.notifier).clearCart(); Navigator.pop(context); },
            child: Text('clear'.tr(ref).toUpperCase(), style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: colorScheme.surface, 
              shape: BoxShape.circle,
              boxShadow: isLight ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 40)] : null,
            ),
            child: Icon(Icons.shopping_bag_outlined, size: 70, color: colorScheme.primary.withValues(alpha: 0.3)),
          ),
          const SizedBox(height: 32),
          Text('empty_cart'.tr(ref), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colorScheme.onBackground)),
          const SizedBox(height: 12),
          Text('Discover premium products and add them here.', textAlign: TextAlign.center, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 14)),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => context.go('/customer'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(180, 56)),
            child: Text('start_shopping'.tr(ref).toUpperCase()),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBillSummary(BuildContext context, WidgetRef ref, dynamic cart) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final colorScheme = theme.colorScheme;
    const double deliveryFee = 100.0;
    double total = cart.totalAmount + deliveryFee;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          decoration: BoxDecoration(
            color: isLight ? Colors.white.withValues(alpha: 0.9) : AppColors.bottomNav.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            boxShadow: [
              BoxShadow(
                color: isLight ? Colors.black.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.4), 
                blurRadius: 40,
                offset: const Offset(0, -10),
              )
            ],
            border: Border.all(color: isLight ? colorScheme.outline.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Detailed Bill Breakdown
              _SummaryRow(label: 'item_total'.tr(ref), value: 'Rs ${cart.totalAmount.toStringAsFixed(0)}', colorScheme: colorScheme),
              const SizedBox(height: 12),
              _SummaryRow(label: 'delivery_fee'.tr(ref), value: 'Rs ${deliveryFee.toStringAsFixed(0)}', colorScheme: colorScheme, isHighlight: true),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: Colors.black26),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('grand_total'.tr(ref), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
                  Text('Rs ${total.toStringAsFixed(0)}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: colorScheme.primary)),
                ],
              ),
              const SizedBox(height: 24),
              // Full Width Checkout Button
              ElevatedButton(
                onPressed: () => context.push('/customer/checkout'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 64),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('checkout'.tr(ref).toUpperCase(), style: const TextStyle(letterSpacing: 1, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme colorScheme;
  final bool isHighlight;

  const _SummaryRow({required this.label, required this.value, required this.colorScheme, this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 14, fontWeight: FontWeight.w600)),
        Text(value, style: TextStyle(color: isHighlight ? AppColors.success : colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  final dynamic item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: isLight ? Colors.black.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.15), 
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          // Product Image with Shadow
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(item.product.imageUrl, width: 90, height: 90, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 20),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.product.name, 
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: colorScheme.onSurface), 
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => ref.read(cartProvider.notifier).removeItem(item.product.id),
                      icon: Icon(Icons.close_rounded, color: colorScheme.onSurface.withValues(alpha: 0.2), size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs ${item.product.price.toStringAsFixed(0)}', 
                  style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 17)
                ),
                const SizedBox(height: 14),
                _QuantitySelector(
                  quantity: item.quantity,
                  onAdd: () => ref.read(cartProvider.notifier).addItem(item.product),
                  onRemove: () => ref.read(cartProvider.notifier).removeItem(item.product.id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  const _QuantitySelector({required this.quantity, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: isLight ? AppColors.lightSecondaryBackground : AppColors.background, 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionButton(icon: Icons.remove_rounded, onTap: onRemove, isLight: isLight),
          Container(
            constraints: const BoxConstraints(minWidth: 40),
            alignment: Alignment.center,
            child: Text(
              '$quantity', 
              style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.onSurface, fontSize: 15)
            ),
          ),
          _ActionButton(icon: Icons.add_rounded, onTap: onAdd, isLight: isLight, isPrimary: true),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isLight;
  final bool isPrimary;
  const _ActionButton({required this.icon, required this.onTap, required this.isLight, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isPrimary ? colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: isPrimary ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.3), size: 20),
      ),
    );
  }
}

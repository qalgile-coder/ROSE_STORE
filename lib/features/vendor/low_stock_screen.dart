import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../models/product_model.dart';
import '../../theme/app_colors.dart';

class LowStockScreen extends ConsumerWidget {
  const LowStockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final lowStockAsync = ref.watch(lowStockProductsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Low Stock Alerts', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: colorScheme.onSurface),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/vendor');
            }
          },
        ),
      ),
      body: lowStockAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.check_circle_outline_rounded, size: 64, color: AppColors.success),
                  ),
                  const SizedBox(height: 24),
                  Text('Inventory lookin\' good!', style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w800, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('All products are well stocked.', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4), fontSize: 14)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _LowStockTile(product: products[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _LowStockTile extends ConsumerWidget {
  final ProductModel product;
  const _LowStockTile({required this.product});

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
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
        boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)] : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  product.imageUrl,
                  width: 68,
                  height: 68,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(width: 68, height: 68, color: colorScheme.onSurface.withOpacity(0.05), child: Icon(Icons.image, color: colorScheme.onSurface.withOpacity(0.1))),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        'REMAINING: ${product.stock} UNITS',
                        style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: colorScheme.outline.withOpacity(0.1)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StockActionButton(
                icon: Icons.add_circle_outline_rounded,
                label: 'Restock',
                onTap: () => _showUpdateStockDialog(context, ref, 50, colorScheme),
                color: colorScheme.primary,
              ),
              _StockActionButton(
                icon: Icons.edit_rounded,
                label: 'Exact Qty',
                onTap: () => _showUpdateStockDialog(context, ref, null, colorScheme),
                color: colorScheme.onSurface,
              ),
              _StockActionButton(
                icon: Icons.block_rounded,
                label: 'Unlist',
                color: AppColors.warning,
                onTap: () {
                  ref.read(vendorServiceProvider).updateProduct(product.id, {'isAvailable': false});
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showUpdateStockDialog(BuildContext context, WidgetRef ref, int? preset, ColorScheme colorScheme) {
    final controller = TextEditingController(text: preset?.toString() ?? product.stock.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Restock Inventory', style: TextStyle(fontWeight: FontWeight.w900)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: ' Units', labelText: 'New Count'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              final newStock = int.tryParse(controller.text);
              if (newStock != null) {
                ref.read(vendorServiceProvider).updateProduct(product.id, {'stock': newStock});
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary),
            child: const Text('UPDATE'),
          ),
        ],
      ),
    );
  }
}

class _StockActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _StockActionButton({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color?.withOpacity(0.8)),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color?.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }
}

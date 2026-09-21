import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization.dart';
import '../../core/providers.dart';
import '../../theme/app_colors.dart';
import '../../models/product_model.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(customerWishlistProvider);
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final primaryColor = isLight ? AppColors.lightPrimary : AppColors.premiumDarkPrimary;
    final textColor = isLight ? AppColors.lightTextPrimary : AppColors.premiumDarkTextPrimary;
    final bgColor = isLight ? AppColors.lightBackground : AppColors.premiumDarkBackground;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('my_wishlist'.tr(ref), style: TextStyle(fontWeight: FontWeight.w900, color: textColor)),
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: wishlistAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.favorite_border_rounded, size: 64, color: primaryColor.withOpacity(0.2)),
                  ),
                  const SizedBox(height: 24),
                  Text('empty_wishlist'.tr(ref), style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('wishlist_hint'.tr(ref), style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 14)),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => context.go('/customer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('explore_now'.tr(ref).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _WishlistTile(product: products[index]),
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: primaryColor)),
        error: (e, s) => Center(child: Text('Error: $e', style: TextStyle(color: AppColors.error))),
      ),
    );
  }
}

class _WishlistTile extends ConsumerWidget {
  final ProductModel product;
  const _WishlistTile({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final cardColor = isLight ? AppColors.lightSurface : AppColors.premiumDarkSurface;
    final textColor = isLight ? AppColors.lightTextPrimary : AppColors.premiumDarkTextPrimary;
    final primaryColor = isLight ? AppColors.lightPrimary : AppColors.premiumDarkPrimary;
    final dividerColor = isLight ? AppColors.lightBorder : AppColors.premiumDarkDivider;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: dividerColor.withOpacity(isLight ? 1 : 0.3)),
        boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)] : null,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: product.imageUrl.isNotEmpty 
              ? Image.network(product.imageUrl, width: 90, height: 90, fit: BoxFit.cover)
              : Container(width: 90, height: 90, color: textColor.withOpacity(0.05), child: const Icon(Icons.image)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name, 
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs ${product.price.toStringAsFixed(0)}', 
                  style: TextStyle(fontWeight: FontWeight.w900, color: primaryColor, fontSize: 18)
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
                onPressed: () {
                  final user = ref.read(userModelProvider).asData?.value;
                  if (user != null) {
                    ref.read(customerServiceProvider).toggleWishlist(user.uid, product);
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.add_shopping_cart_rounded, color: primaryColor),
                onPressed: () {
                  ref.read(cartProvider.notifier).addItem(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${product.name} added to cart'), duration: const Duration(seconds: 1)),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../theme/app_colors.dart';
import '../../models/product_model.dart';

class CustomerAllProductsScreen extends ConsumerWidget {
  const CustomerAllProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // يمكنك تعديل الـ Provider هنا إلى allProductsProvider إذا كان مخصصاً لجلب كل المنتجات
    final productsAsync = ref.watch(trendingProductsProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bgColor = isLight ? AppColors.lightBackground : AppColors.premiumDarkBackground;
    final textColor = isLight ? AppColors.lightTextPrimary : AppColors.premiumDarkTextPrimary;
    final primaryColor = isLight ? AppColors.lightPrimary : AppColors.premiumDarkPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'All Products',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 18)
        ),
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: productsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Text(
                'No products available',
                style: TextStyle(color: textColor, fontWeight: FontWeight.w600)
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.68,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return _GridProductCard(product: products[index]);
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: primaryColor)),
        error: (e, s) => Center(
          child: Text(
            'Error loading products',
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600)
          ),
        ),
      ),
    );
  }
}

class _GridProductCard extends ConsumerWidget {
  final ProductModel product;
  const _GridProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final primaryColor = isLight ? AppColors.lightPrimary : AppColors.premiumDarkPrimary;
    final cardColor = isLight ? AppColors.lightSurface : AppColors.premiumDarkSurface;
    final textColor = isLight ? AppColors.lightTextPrimary : AppColors.premiumDarkTextPrimary;
    final secondaryTextColor = isLight ? AppColors.lightTextSecondary : AppColors.premiumDarkTextSecondary;

    final double originalPrice = product.price;
    final double discountPercent = product.discount;
    final bool hasDiscount = discountPercent > 0;
    
    final double finalPrice = hasDiscount 
        ? originalPrice - (originalPrice * (discountPercent / 100)) 
        : originalPrice;

    return InkWell(
      onTap: () => GoRouter.of(context).go('/product/${product.id}'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor, 
          borderRadius: BorderRadius.circular(24),
          boxShadow: isLight ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5))] : null,
          border: isLight ? Border.all(color: AppColors.lightBorder) : Border.all(color: AppColors.premiumDarkDivider.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: product.imageUrl.isNotEmpty
                        ? Image.network(product.imageUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                        : Container(
                            width: double.infinity, 
                            color: isLight ? AppColors.lightSecondaryBackground : AppColors.premiumDarkSecondaryBackground, 
                            child: Center(child: Icon(Icons.image, color: textColor.withValues(alpha: 0.1)))
                          ),
                  ),
                  if (hasDiscount)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-${discountPercent.round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              product.name,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: textColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              product.description.isNotEmpty ? product.description : 'Merchant Product',
              style: TextStyle(color: secondaryTextColor.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasDiscount) ...[
                  Row(
                    children: [
                      Text(
                        'Rs ${originalPrice.round()}',
                        style: TextStyle(
                          color: secondaryTextColor.withValues(alpha: 0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs ${finalPrice.round()}', 
                      style: TextStyle(
                        color: hasDiscount ? Colors.green.shade700 : primaryColor, 
                        fontWeight: FontWeight.w900, 
                        fontSize: 14.5,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        ref.read(cartProvider.notifier).addItem(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 16),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'تم إضافة "${product.name}" إلى السلة',
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            margin: const EdgeInsets.all(16),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [primaryColor, primaryColor.withValues(alpha: 0.8)]),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.4), 
                              blurRadius: 8, 
                              offset: const Offset(0, 3)
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
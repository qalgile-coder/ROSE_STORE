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
              childAspectRatio: 0.75,
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

class _GridProductCard extends StatelessWidget {
  final ProductModel product;
  const _GridProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final primaryColor = isLight ? AppColors.lightPrimary : AppColors.premiumDarkPrimary;
    final cardColor = isLight ? AppColors.lightSurface : AppColors.premiumDarkSurface;
    final textColor = isLight ? AppColors.lightTextPrimary : AppColors.premiumDarkTextPrimary;
    final secondaryTextColor = isLight ? AppColors.lightTextSecondary : AppColors.premiumDarkTextSecondary;

    return InkWell(
      onTap: () => context.push('/customer/product', extra: product),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor, 
          borderRadius: BorderRadius.circular(24),
          boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))] : null,
          border: isLight ? Border.all(color: AppColors.lightBorder) : Border.all(color: AppColors.premiumDarkDivider.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: product.imageUrl.isNotEmpty 
                    ? Image.network(product.imageUrl, fit: BoxFit.cover, width: double.infinity)
                    : Container(
                        width: double.infinity, 
                        color: isLight ? AppColors.lightSecondaryBackground : AppColors.premiumDarkSecondaryBackground, 
                        child: Center(child: Icon(Icons.image, color: textColor.withOpacity(0.1)))
                      ),
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
              style: TextStyle(color: secondaryTextColor.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rs ${product.price.round()}', 
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 14)
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.add_rounded, color: primaryColor, size: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/providers.dart';
import '../../core/localization.dart';
import '../../models/product_model.dart';
import '../../models/review_model.dart';
import '../../theme/app_colors.dart';

class ProductDetailsScreen extends ConsumerWidget {
  final ProductModel product;
  const ProductDetailsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final wishlist = ref.watch(customerWishlistProvider).asData?.value ?? [];
    final isWishlisted = wishlist.any((p) => p.id == product.id);
    final reviewsAsync = ref.watch(productReviewsProvider(product.id));

    // Watch real-time product data for live updates on ratings and order count
    final liveProductAsync = ref.watch(productDetailProvider(product.id));
    final liveProduct = liveProductAsync.asData?.value ?? product;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildModernAppBar(context, ref, isWishlisted),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 150),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _Badge(label: liveProduct.category, color: colorScheme.primary),
                          _RatingBadge(
                            rating: liveProduct.rating.toStringAsFixed(1), 
                            count: liveProduct.reviewCount.toString(),
                            onTap: () => context.push('/customer/product-reviews/${liveProduct.id}/${liveProduct.name}'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        liveProduct.name,
                        style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: colorScheme.onSurface, letterSpacing: -1),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${'by'.tr(ref)} ${liveProduct.brand}',
                        style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 32),
                      _PriceSection(price: liveProduct.price, discount: liveProduct.discount),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Divider(color: colorScheme.outline.withValues(alpha: 0.1)),
                      ),
                      
                      Row(
                        children: [
                          _StatItem(
                            icon: Icons.local_mall_rounded,
                            label: '${'ordered'.tr(ref)} ${liveProduct.orderCount} ${'times'.tr(ref)}',
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 24),
                          _StatItem(
                            icon: Icons.verified_rounded,
                            label: 'Premium Quality',
                            color: AppColors.success,
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),
                      Text('description'.tr(ref), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colorScheme.onBackground)),
                      const SizedBox(height: 12),
                      Text(
                        liveProduct.description,
                        style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7), height: 1.7, fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 40),
                      _StockCard(stock: liveProduct.stock),
                      const SizedBox(height: 48),
                      
                      _buildReviewsHeader(context, ref, liveProduct),
                      const SizedBox(height: 20),
                      _buildReviewsList(ref, reviewsAsync, textColor: colorScheme.onBackground, secondaryColor: colorScheme.onSurface),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildFloatingAction(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsHeader(BuildContext context, WidgetRef ref, ProductModel liveProduct) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('customer_reviews'.tr(ref), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onBackground)),
        if (liveProduct.reviewCount > 0)
          TextButton(
            onPressed: () => context.push('/customer/product-reviews/${liveProduct.id}/${liveProduct.name}'),
            child: Text('view_all'.tr(ref), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  Widget _buildReviewsList(WidgetRef ref, AsyncValue<List<ReviewModel>> reviewsAsync, {required Color textColor, required Color secondaryColor}) {
    return reviewsAsync.when(
      data: (reviews) {
        if (reviews.isEmpty) return Text('no_reviews'.tr(ref), style: TextStyle(color: secondaryColor.withValues(alpha: 0.5)));
        return Column(
          children: reviews.take(3).map((r) => _ReviewTile(review: r, textColor: textColor, secondaryColor: secondaryColor)).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text('Error loading reviews: $e'),
    );
  }

  void _shareProduct() {
    final link = 'https://zenmartpro.app/product/${product.id}';
    Share.share(
      'Check out this ${product.name} on Zen Mart Pro!\n\nBuy it here: $link',
      subject: 'Great deal on Zen Mart Pro!',
    );
  }

  Widget _buildModernAppBar(BuildContext context, WidgetRef ref, bool isWishlisted) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return SliverAppBar(
      expandedHeight: 420,
      pinned: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: isLight ? Colors.white.withValues(alpha: 0.8) : AppColors.surface.withValues(alpha: 0.8),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: colorScheme.onSurface),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      actions: [
        _CircleActionBtn(
          icon: Icons.share_rounded, 
          onTap: _shareProduct,
        ),
        const SizedBox(width: 12),
        _CircleActionBtn(
          icon: isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded, 
          color: isWishlisted ? Colors.redAccent : null,
          onTap: () {
            final user = ref.read(userModelProvider).asData?.value;
            if (user != null) {
              ref.read(customerServiceProvider).toggleWishlist(user.uid, product);
            }
          }
        ),
        const SizedBox(width: 12),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'product_${product.id}',
          child: Container(
            color: isLight ? AppColors.lightSecondaryBackground : AppColors.secondaryBackground,
            child: product.imageUrl.isNotEmpty 
                ? Image.network(product.imageUrl, fit: BoxFit.contain)
                : Center(child: Icon(Icons.image, size: 80, color: colorScheme.onSurface.withValues(alpha: 0.05))),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingAction(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final colorScheme = theme.colorScheme;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          decoration: BoxDecoration(
            color: isLight ? Colors.white.withValues(alpha: 0.9) : AppColors.bottomNav.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            boxShadow: [
              BoxShadow(
                color: isLight ? Colors.black.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.3), 
                blurRadius: 40
              )
            ],
            border: Border.all(color: isLight ? colorScheme.outline.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              _ActionSquareBtn(
                icon: Icons.share_rounded, 
                onTap: () {},
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(cartProvider.notifier).addItem(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.name} added to bag'),
                        backgroundColor: colorScheme.primary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  child: Text('add_to_bag'.tr(ref)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final ReviewModel review;
  final Color textColor;
  final Color secondaryColor;
  const _ReviewTile({required this.review, required this.textColor, required this.secondaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(review.customerName, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14)),
              Row(
                children: List.generate(5, (index) => Icon(
                  Icons.star_rounded, 
                  size: 14, 
                  color: index < review.rating ? Colors.orange : Colors.grey[300]
                )),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('dd MMM yyyy').format(review.createdAt),
            style: TextStyle(color: secondaryColor.withValues(alpha: 0.4), fontSize: 11),
          ),
          const SizedBox(height: 12),
          Text(
            review.review,
            style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 13, height: 1.4),
          ),
          if (review.reply != null && review.reply!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('STORE RESPONSE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 9, color: Theme.of(context).colorScheme.primary, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(review.reply!, style: TextStyle(fontSize: 12, height: 1.3, color: textColor.withValues(alpha: 0.6), fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Text(label.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)));
}

class _RatingBadge extends StatelessWidget {
  final String rating;
  final String count;
  final VoidCallback onTap;
  const _RatingBadge({required this.rating, required this.count, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Row(children: [const Icon(Icons.star_rounded, color: AppColors.warning, size: 20), const SizedBox(width: 6), Text(rating, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)), const SizedBox(width: 4), Text('($count)', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3), fontSize: 13, fontWeight: FontWeight.w600))]),
  );
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatItem({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color.withOpacity(0.8)),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _PriceSection extends StatelessWidget {
  final double price;
  final double discount;
  const _PriceSection({required this.price, required this.discount});
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end, 
      children: [
        Text('Rs ${price.toStringAsFixed(0)}', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: colorScheme.primary, letterSpacing: -1)), 
        if (discount > 0) ...[
          const SizedBox(width: 14), 
          Padding(
            padding: const EdgeInsets.only(bottom: 6), 
            child: Text('Rs ${(price + discount).round()}', style: TextStyle(fontSize: 18, color: colorScheme.onSurface.withOpacity(0.3), decoration: TextDecoration.lineThrough, fontWeight: FontWeight.w600))
          )
        ]
      ]
    );
  }
}

class _StockCard extends StatelessWidget {
  final int stock;
  const _StockCard({required this.stock});
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ref = Consumer(builder: (context, ref, _) => const SizedBox()); // Dummy to get access to localization context if needed
    bool isLow = stock < 10;
    return Consumer(
      builder: (context, ref, _) {
        return Container(
          padding: const EdgeInsets.all(24), 
          decoration: BoxDecoration(
            color: colorScheme.surface, 
            borderRadius: BorderRadius.circular(28),
          ), 
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12), 
                decoration: BoxDecoration(color: (isLow ? AppColors.warning : AppColors.info).withOpacity(0.1), shape: BoxShape.circle), 
                child: Icon(isLow ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: isLow ? AppColors.warning : AppColors.info, size: 24)
              ), 
              const SizedBox(width: 16), 
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    Text(isLow ? 'low_stock'.tr(ref).toUpperCase() : 'in_stock'.tr(ref).toUpperCase(), style: TextStyle(color: isLow ? AppColors.warning : AppColors.info, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)), 
                    const SizedBox(height: 4), 
                    Text(isLow ? '${'only'.tr(ref)} $stock ${'items_left'.tr(ref)}' : 'ready_ship'.tr(ref), style: TextStyle(color: colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w600))
                  ]
                )
              )
            ]
          )
        );
      }
    );
  }
}

class _CircleActionBtn extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  const _CircleActionBtn({required this.icon, this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 10), 
      child: CircleAvatar(
        backgroundColor: isLight ? Colors.white.withValues(alpha: 0.8) : AppColors.surface.withValues(alpha: 0.8), 
        child: IconButton(icon: Icon(icon, size: 20, color: color ?? colorScheme.onSurface), onPressed: onTap)
      )
    );
  }
}

class _ActionSquareBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ActionSquareBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return InkWell(
      onTap: onTap, 
      borderRadius: BorderRadius.circular(18), 
      child: Container(
        height: 60, 
        width: 60, 
        decoration: BoxDecoration(
          color: colorScheme.surface, 
          borderRadius: BorderRadius.circular(18), 
          border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
          boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] : null,
        ), 
        child: Icon(icon, color: colorScheme.onSurface, size: 24)
      )
    );
  }
}

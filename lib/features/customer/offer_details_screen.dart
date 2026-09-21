import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../models/offer_model.dart';
import '../../theme/app_colors.dart';

class OfferDetailsScreen extends ConsumerWidget {
  final OfferModel offer;
  const OfferDetailsScreen({super.key, required this.offer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopsAsync = ref.watch(offerShopsProvider(offer.applicableShopIds));
    final productsAsync = ref.watch(offerProductsProvider(offer.applicableProductIds));
    
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: isLight ? Colors.white.withOpacity(0.8) : AppColors.premiumDarkSurface.withOpacity(0.8),
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: colorScheme.onSurface),
                  onPressed: () => context.canPop() ? context.pop() : context.go('/customer'),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                offer.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  color: colorScheme.surface,
                  child: Icon(Icons.local_offer_rounded, size: 80, color: colorScheme.onSurface.withOpacity(0.1)),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          offer.offerType == 'percentage' 
                              ? '${offer.value.round()}% OFF' 
                              : offer.offerType == 'free_delivery' 
                                  ? 'FREE DELIVERY' 
                                  : 'Rs ${offer.value.round()} OFF',
                          style: TextStyle(color: isLight ? Colors.white : AppColors.premiumDarkBackground, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                        ),
                      ),
                      if (offer.couponCode != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: colorScheme.primary.withOpacity(0.3), width: 1.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.qr_code_rounded, size: 16, color: colorScheme.primary),
                              const SizedBox(width: 10),
                              Text(
                                offer.couponCode!,
                                style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(offer.title, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: colorScheme.onBackground, letterSpacing: -1)),
                  const SizedBox(height: 12),
                  Text(
                    offer.description,
                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 15, height: 1.6, fontWeight: FontWeight.w500),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Divider(color: colorScheme.outline.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),

          if (offer.applicableShopIds.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(
                child: Text('PARTICIPATING STORES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: colorScheme.primary, letterSpacing: 1.5)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: shopsAsync.when(
                data: (shops) => SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _SmallShopTile(shop: shops[index], colorScheme: colorScheme, isLight: isLight),
                    childCount: shops.length,
                  ),
                ),
                loading: () => SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: colorScheme.primary))),
                error: (e, s) => const SliverToBoxAdapter(child: Center(child: Text('Error loading shops'))),
              ),
            ),
          ],

          if (offer.applicableProductIds.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              sliver: SliverToBoxAdapter(
                child: Text('ELIGIBLE PRODUCTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: colorScheme.primary, letterSpacing: 1.5)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: productsAsync.when(
                data: (products) => SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.82,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ProductOfferCard(product: products[index], colorScheme: colorScheme, isLight: isLight),
                    childCount: products.length,
                  ),
                ),
                loading: () => SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: colorScheme.primary))),
                error: (e, s) => const SliverToBoxAdapter(child: Center(child: Text('Error loading products'))),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _SmallShopTile extends StatelessWidget {
  final dynamic shop; 
  final ColorScheme colorScheme;
  final bool isLight;
  const _SmallShopTile({required this.shop, required this.colorScheme, required this.isLight});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: isLight ? BorderSide(color: colorScheme.outline.withOpacity(0.1)) : BorderSide.none,
        ),
        child: ListTile(
          onTap: () => context.push('/customer/shop/${shop.id}'),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(shop.imageUrl, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(width: 48, height: 48, color: colorScheme.surface, child: Icon(Icons.storefront, color: colorScheme.onSurface.withOpacity(0.1), size: 20))),
          ),
          title: Text(shop.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: colorScheme.onSurface)),
          subtitle: Text(shop.category, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.w600)),
          trailing: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: colorScheme.primary),
          ),
        ),
      ),
    );
  }
}

class _ProductOfferCard extends StatelessWidget {
  final dynamic product;
  final ColorScheme colorScheme;
  final bool isLight;
  const _ProductOfferCard({required this.product, required this.colorScheme, required this.isLight});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/customer/product', extra: product),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: isLight ? Border.all(color: colorScheme.outline.withOpacity(0.1)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: product.imageUrl.isNotEmpty 
                  ? Image.network(product.imageUrl, fit: BoxFit.cover, width: double.infinity)
                  : Container(color: isLight ? AppColors.lightSecondaryBackground : AppColors.premiumDarkSecondaryBackground, child: Icon(Icons.image, color: colorScheme.onSurface.withOpacity(0.1))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name, 
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: colorScheme.onSurface), 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rs ${product.price.toStringAsFixed(0)}', 
                    style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 15)
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

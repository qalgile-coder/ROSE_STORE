import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../models/shop_model.dart';
import '../../theme/app_colors.dart';

class FeaturedShopsScreen extends ConsumerStatefulWidget {
  const FeaturedShopsScreen({super.key});

  @override
  ConsumerState<FeaturedShopsScreen> createState() => _FeaturedShopsScreenState();
}

class _FeaturedShopsScreenState extends ConsumerState<FeaturedShopsScreen> {
  String _sortBy = 'Rating';

  @override
  Widget build(BuildContext context) {
    final featuredAsync = ref.watch(featuredShopsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Featured Stores', style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.onBackground)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: colorScheme.onBackground),
          onPressed: () => context.pop(),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.sort_rounded, color: colorScheme.primary),
            color: colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (val) => setState(() => _sortBy = val),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'Rating', child: Text('Rating', style: TextStyle(color: colorScheme.onSurface))),
              PopupMenuItem(value: 'Delivery Time', child: Text('Speed', style: TextStyle(color: colorScheme.onSurface))),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: featuredAsync.when(
        data: (shops) {
          var sortedShops = List<ShopModel>.from(shops);
          if (_sortBy == 'Rating') {
            sortedShops.sort((a, b) => b.rating.compareTo(a.rating));
          } else if (_sortBy == 'Delivery Time') {
            sortedShops.sort((a, b) => a.deliveryTime.compareTo(b.deliveryTime));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: sortedShops.length,
            physics: const BouncingScrollPhysics(),
            separatorBuilder: (_, __) => const SizedBox(height: 24),
            itemBuilder: (context, index) => _FeaturedShopBigCard(
              shop: sortedShops[index],
              isLight: isLight,
              colorScheme: colorScheme,
            ),
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: colorScheme.primary)),
        error: (e, s) => Center(child: Text('Error: $e', style: TextStyle(color: colorScheme.error))),
      ),
    );
  }
}

class _FeaturedShopBigCard extends StatelessWidget {
  final ShopModel shop;
  final bool isLight;
  final ColorScheme colorScheme;

  const _FeaturedShopBigCard({required this.shop, required this.isLight, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/customer/shop/${shop.id}'),
      borderRadius: BorderRadius.circular(32),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: isLight ? Colors.black.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.2), 
              blurRadius: 30, 
              offset: const Offset(0, 10)
            ),
          ],
          border: isLight ? Border.all(color: colorScheme.outline.withValues(alpha: 0.1)) : Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'shop_banner_featured_${shop.id}',
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      image: shop.imageUrl.isNotEmpty 
                          ? DecorationImage(image: NetworkImage(shop.imageUrl), fit: BoxFit.cover)
                          : null,
                      color: isLight ? AppColors.lightSecondaryBackground : AppColors.premiumDarkSecondaryBackground,
                    ),
                    child: shop.imageUrl.isEmpty 
                        ? Center(child: Icon(Icons.storefront, size: 64, color: colorScheme.onSurface.withValues(alpha: 0.1)))
                        : null,
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: AppColors.warning, size: 18),
                            const SizedBox(width: 4),
                            Text(shop.rating.toString(), style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (shop.hasFreeDelivery)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('FREE DELIVERY', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          shop.name, 
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: colorScheme.onSurface, letterSpacing: -0.5)
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          shop.deliveryTime, 
                          style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.primary, fontSize: 11, letterSpacing: 0.5)
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${shop.category} • ${shop.address}', 
                    style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _Tag(label: 'Featured', color: colorScheme.primary),
                      const SizedBox(width: 10),
                      if (shop.isOpen) 
                        const _Tag(label: 'Open Now', color: AppColors.success)
                      else
                        _Tag(label: 'Closed', color: colorScheme.error),
                    ],
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

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }
}

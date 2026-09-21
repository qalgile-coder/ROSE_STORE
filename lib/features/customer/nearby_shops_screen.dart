import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../models/shop_model.dart';
import '../../theme/app_colors.dart';

class NearbyShopsScreen extends ConsumerStatefulWidget {
  const NearbyShopsScreen({super.key});

  @override
  ConsumerState<NearbyShopsScreen> createState() => _NearbyShopsScreenState();
}

class _NearbyShopsScreenState extends ConsumerState<NearbyShopsScreen> {
  String _sortBy = 'Nearby';

  @override
  Widget build(BuildContext context) {
    final nearbyAsync = ref.watch(nearbyShopsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Stores Near You', style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.onBackground)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
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
              PopupMenuItem(value: 'Nearby', child: Text('Distance', style: TextStyle(color: colorScheme.onSurface))),
              PopupMenuItem(value: 'Rating', child: Text('Rating', style: TextStyle(color: colorScheme.onSurface))),
              PopupMenuItem(value: 'Delivery Fee', child: Text('Fee', style: TextStyle(color: colorScheme.onSurface))),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: nearbyAsync.when(
        data: (shops) {
          if (shops.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.store_rounded, size: 64, color: colorScheme.onSurface.withOpacity(0.1)),
                  const SizedBox(height: 16),
                  Text('No stores found nearby', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }

          var sortedShops = List<ShopModel>.from(shops);
          if (_sortBy == 'Rating') {
            sortedShops.sort((a, b) => b.rating.compareTo(a.rating));
          } else if (_sortBy == 'Delivery Fee') {
            sortedShops.sort((a, b) => a.deliveryFee.compareTo(b.deliveryFee));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: sortedShops.length,
            physics: const BouncingScrollPhysics(),
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _NearbyShopTile(
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

class _NearbyShopTile extends StatelessWidget {
  final ShopModel shop;
  final bool isLight;
  final ColorScheme colorScheme;

  const _NearbyShopTile({required this.shop, required this.isLight, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/customer/shop/${shop.id}'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)] : null,
          border: Border.all(color: colorScheme.outline.withOpacity(isLight ? 0.1 : 0.2)),
        ),
        child: Row(
          children: [
            Hero(
              tag: 'shop_nearby_${shop.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: shop.imageUrl.isNotEmpty 
                    ? Image.network(shop.imageUrl, width: 90, height: 90, fit: BoxFit.cover)
                    : Container(width: 90, height: 90, color: isLight ? AppColors.lightSecondaryBackground : AppColors.premiumDarkSecondaryBackground, child: Center(child: Icon(Icons.storefront, color: colorScheme.onSurface.withOpacity(0.1)))),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          shop.name, 
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: colorScheme.onSurface, letterSpacing: -0.2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.warning, size: 14),
                          const SizedBox(width: 2),
                          Text(shop.rating.toString(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: colorScheme.onSurface)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${shop.category} • ${shop.deliveryTime}', 
                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          shop.hasFreeDelivery ? 'FREE DELIVERY' : 'Rs ${shop.deliveryFee.round()} FEE',
                          style: const TextStyle(color: AppColors.success, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '1.2 km away', 
                        style: TextStyle(color: colorScheme.onSurface.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colorScheme.onSurface.withOpacity(0.1)),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

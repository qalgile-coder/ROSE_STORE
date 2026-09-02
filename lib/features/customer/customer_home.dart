import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../theme/app_colors.dart';
import '../../models/shop_model.dart';
import '../../models/product_model.dart';
import './widgets/customer_bottom_nav.dart';
import '../../core/localization.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class CustomerHome extends ConsumerWidget {
  const CustomerHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final connectivity = ref.watch(connectivityProvider).asData?.value;
    final isOffline = connectivity == ConnectivityResult.none;
    
    // Dynamic Theme Mapping
    final bgColor = isLight ? AppColors.lightBackground : AppColors.premiumDarkBackground;
    final primaryColor = isLight ? AppColors.lightPrimary : AppColors.premiumDarkPrimary;
    final textColor = isLight ? AppColors.lightTextPrimary : AppColors.premiumDarkTextPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background Gradient Glow
          Positioned(
            top: -200,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [primaryColor.withValues(alpha: isLight ? 0.12 : 0.08), Colors.transparent],
                ),
              ),
            ),
          ),
          
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 160,
                floating: true,
                pinned: true,
                elevation: 0,
                backgroundColor: bgColor.withOpacity(0.8),
                flexibleSpace: FlexibleSpaceBar(
                  background: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(color: Colors.transparent),
                  ),
                ),
                title: _LocationHeader(ref: ref),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(80),
                  child: Column(
                    children: [
                      if (isOffline)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          color: AppColors.error.withOpacity(0.8),
                          child: const Center(
                            child: Text(
                              'WORKING OFFLINE • VIEWING CACHED DATA',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                            ),
                          ),
                        ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 10, 20, 20),
                        child: _SearchBar(),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      const _PromoBanner(),
                      const SizedBox(height: 40),
                      _SectionHeader(title: 'Quick Categories', showSeeAll: false, textColor: textColor, primaryColor: primaryColor),
                      const SizedBox(height: 20),
                      const _CategoryGrid(),
                      const SizedBox(height: 40),
                      _SectionHeader(
                        title: 'featured_stores'.tr(ref), 
                        showSeeAll: true,
                        onSeeAll: '/customer/featured-shops',
                        textColor: textColor,
                        primaryColor: primaryColor,
                      ),
                      const SizedBox(height: 20),
                      const _FeaturedShops(),
                      const SizedBox(height: 40),
                      _SectionHeader(
                        title: 'Trending Now', 
                        showSeeAll: true, 
                        onSeeAll: '/customer/trending-products',
                        textColor: textColor, 
                        primaryColor: primaryColor
                      ),
                      const SizedBox(height: 20),
                      const _TrendingProducts(),
                      const SizedBox(height: 40),
                      _SectionHeader(
                        title: 'popular_near'.tr(ref), 
                        showSeeAll: true, 
                        onSeeAll: '/customer/nearby-shops',
                        textColor: textColor, 
                        primaryColor: primaryColor
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              const _NearbyShopsGrid(),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          
          // Floating Bottom Nav
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: const CustomerBottomNav(currentIndex: 0),
          ),
        ],
      ),
    );
  }
}

class _LocationHeader extends StatelessWidget {
  final WidgetRef ref;
  const _LocationHeader({required this.ref});

  @override
  Widget build(BuildContext context) {
    final defaultAddress = ref.watch(defaultAddressProvider);
    final user = ref.watch(userModelProvider).asData?.value;
    final isLight = Theme.of(context).brightness == Brightness.light;
    
    final primaryColor = isLight ? AppColors.lightPrimary : AppColors.premiumDarkPrimary;
    final textColor = isLight ? AppColors.lightTextPrimary : AppColors.premiumDarkTextPrimary;
    final cardColor = isLight ? Colors.white : const Color(0xFF1E293B);

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => context.push('/customer/addresses'),
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.location_on_rounded, color: primaryColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'deliver_to'.tr(ref).toUpperCase(),
                        style: TextStyle(
                          color: primaryColor.withOpacity(0.8),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              defaultAddress?.fullAddress ?? 'Select Location',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: textColor.withOpacity(0.4)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _HeaderActionBtn(
          icon: Icons.notifications_none_rounded, 
          onTap: () => context.push('/customer/notifications'),
          cardColor: cardColor,
          textColor: textColor,
          isLight: isLight,
        ),
        const SizedBox(width: 12),
        _HeaderActionBtn(
          icon: Icons.favorite_border_rounded, 
          onTap: () => context.push('/customer/wishlist'),
          cardColor: cardColor,
          textColor: textColor,
          isLight: isLight,
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => context.push('/customer/profile'),
          child: Hero(
            tag: 'profile_avatar',
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primaryColor.withOpacity(0.3), width: 1.5),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: cardColor,
                backgroundImage: (user?.profilePicture != null && user!.profilePicture!.isNotEmpty)
                    ? NetworkImage(user.profilePicture!)
                    : null,
                child: (user?.profilePicture == null || user!.profilePicture!.isEmpty)
                    ? Text(
                        user?.name.substring(0, 1).toUpperCase() ?? '?',
                        style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color cardColor;
  final Color textColor;
  final bool isLight;
  const _HeaderActionBtn({required this.icon, required this.onTap, required this.cardColor, required this.textColor, required this.isLight});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isLight ? AppColors.lightBorder : AppColors.premiumDarkDivider),
          boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] : null,
        ),
        child: Icon(icon, color: textColor, size: 20),
      ),
    );
  }
}

class _SearchBar extends ConsumerWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final primaryColor = isLight ? AppColors.lightPrimary : AppColors.premiumDarkPrimary;
    final cardColor = isLight ? AppColors.lightSurface : AppColors.premiumDarkSurface;
    final secondaryTextColor = isLight ? AppColors.lightTextSecondary : AppColors.premiumDarkTextSecondary;

    return GestureDetector(
      onTap: () => context.push('/customer/search'),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isLight ? Colors.black.withOpacity(0.05) : Colors.black.withOpacity(0.15), 
              blurRadius: 30, 
              offset: const Offset(0, 10)
            ),
          ],
          border: Border.all(color: isLight ? AppColors.lightBorder : AppColors.premiumDarkDivider.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: primaryColor, size: 24),
            const SizedBox(width: 14),
            Text(
              'search_hint'.tr(ref),
              style: TextStyle(color: secondaryTextColor.withOpacity(0.5), fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.tune_rounded, color: primaryColor, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoBanner extends ConsumerWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(activeOffersProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final primaryColor = isLight ? AppColors.lightPrimary : AppColors.premiumDarkPrimary;

    return offersAsync.when(
      data: (offers) {
        if (offers.isEmpty) return const SizedBox.shrink();
        final offer = offers.first;

        return Container(
          width: double.infinity,
          height: 190,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: isLight ? primaryColor.withOpacity(0.1) : Colors.black.withOpacity(0.3), 
                blurRadius: 40, 
                offset: const Offset(0, 20)
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    offer.imageUrl.isNotEmpty ? offer.imageUrl : 'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?q=80&w=600',
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          offer.offerType == 'percentage' ? '${offer.value.round()}% OFF' : 'VIP DEAL',
                          style: TextStyle(color: isLight ? Colors.white : AppColors.premiumDarkBackground, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        offer.title,
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => context.push('/customer/offer', extra: offer),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(110, 44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('SHOP NOW'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => _Skeleton(height: 190, radius: 36),
      error: (e, s) => const SizedBox.shrink(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool showSeeAll;
  final String? onSeeAll;
  final Color textColor;
  final Color primaryColor;
  const _SectionHeader({required this.title, required this.showSeeAll, this.onSeeAll, required this.textColor, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.w900, 
              color: textColor, 
              letterSpacing: -0.5
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (showSeeAll)
          Consumer(
            builder: (context, ref, child) => TextButton(
              onPressed: () {
                if (onSeeAll != null) {
                  context.push(onSeeAll!);
                }
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('view_all'.tr(ref), style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward_ios_rounded, size: 12, color: primaryColor),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid();

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cardColor = isLight ? AppColors.lightSurface : AppColors.premiumDarkSurface;
    final secondaryTextColor = isLight ? AppColors.lightTextSecondary : AppColors.premiumDarkTextSecondary;

    return Consumer(
      builder: (context, ref, child) {
        final categories = [
          {'name': 'grocery'.tr(ref), 'key': 'Grocery', 'icon': Icons.local_grocery_store_rounded, 'color': const Color(0xFF6366F1)},
          {'name': 'food'.tr(ref), 'key': 'Food', 'icon': Icons.restaurant_rounded, 'color': const Color(0xFFF59E0B)},
          {'name': 'pharmacy'.tr(ref), 'key': 'Pharmacy', 'icon': Icons.medical_services_rounded, 'color': const Color(0xFF10B981)},
          {'name': 'fashion'.tr(ref), 'key': 'Fashion', 'icon': Icons.checkroom_rounded, 'color': const Color(0xFFEC4899)},
        ];

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: categories.map((cat) {
              final color = cat['color'] as Color;
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: InkWell(
                  onTap: () => context.push('/customer/category/${cat['key']}'),
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    children: [
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: isLight ? color.withOpacity(0.15) : AppColors.premiumDarkDivider.withOpacity(0.5), width: 1),
                          boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15)] : null,
                        ),
                        child: Center(child: Icon(cat['icon'] as IconData, color: color, size: 30)),
                      ),
                      const SizedBox(height: 12),
                      Text(cat['name'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: secondaryTextColor)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _FeaturedShops extends ConsumerWidget {
  const _FeaturedShops();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuredAsync = ref.watch(featuredShopsProvider);

    return featuredAsync.when(
      data: (shops) {
        if (shops.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: shops.length,
            padding: const EdgeInsets.only(right: 20),
            separatorBuilder: (_, __) => const SizedBox(width: 20),
            itemBuilder: (context, index) => _FeaturedShopCard(shop: shops[index]),
          ),
        );
      },
      loading: () => SizedBox(height: 260, child: ListView(scrollDirection: Axis.horizontal, children: List.generate(2, (_) => Padding(padding: const EdgeInsets.only(right: 20), child: _Skeleton(width: 280, height: 260, radius: 32))))),
      error: (e, s) => const SizedBox.shrink(),
    );
  }
}

class _FeaturedShopCard extends StatelessWidget {
  final ShopModel shop;
  const _FeaturedShopCard({required this.shop});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final cardColor = isLight ? AppColors.lightSurface : AppColors.premiumDarkSurface;
    final textColor = isLight ? AppColors.lightTextPrimary : AppColors.premiumDarkTextPrimary;
    final secondaryTextColor = isLight ? AppColors.lightTextSecondary : AppColors.premiumDarkTextSecondary;

    return InkWell(
      onTap: () => context.push('/customer/shop/${shop.id}'),
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: 290,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: isLight ? Colors.black.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.2), 
              blurRadius: 30, 
              offset: const Offset(0, 10)
            )
          ],
          border: Border.all(color: isLight ? AppColors.lightBorder : AppColors.premiumDarkDivider.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  child: Hero(
                    tag: 'shop_home_${shop.id}',
                    child: shop.imageUrl.isNotEmpty 
                        ? Image.network(shop.imageUrl, height: 155, width: double.infinity, fit: BoxFit.cover)
                        : Container(height: 155, color: isLight ? AppColors.lightSecondaryBackground : AppColors.premiumDarkSecondaryBackground, child: Center(child: Icon(Icons.storefront, color: textColor.withValues(alpha: 0.1), size: 50))),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: _GlassBadge(label: '${shop.rating}', icon: Icons.star_rounded, color: AppColors.warning),
                ),
                if (shop.hasFreeDelivery)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: _GlassBadge(label: 'FREE', icon: Icons.bolt_rounded, color: AppColors.success),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          shop.name, 
                          style: TextStyle(
                            fontWeight: FontWeight.w900, 
                            fontSize: 17, 
                            color: textColor, 
                            letterSpacing: -0.2
                          ), 
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        shop.deliveryTime,
                        style: TextStyle(color: theme.colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${shop.category} • ${shop.address}', 
                    style: TextStyle(
                      color: secondaryTextColor.withValues(alpha: 0.7), 
                      fontSize: 12, 
                      fontWeight: FontWeight.w600
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _TrendingProducts extends ConsumerWidget {
  const _TrendingProducts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(trendingProductsProvider);

    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        
        return SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) => _SmallProductCard(product: products[index]),
          ),
        );
      },
      loading: () => SizedBox(height: 120, child: ListView(scrollDirection: Axis.horizontal, children: List.generate(2, (_) => Padding(padding: const EdgeInsets.only(right: 16), child: _Skeleton(width: 240, height: 120, radius: 20))))),
      error: (e, s) => const SizedBox.shrink(),
    );
  }
}

class _SmallProductCard extends StatelessWidget {
  final ProductModel product;
  const _SmallProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final primaryColor = isLight ? AppColors.lightPrimary : AppColors.premiumDarkPrimary;
    final cardColor = isLight ? AppColors.lightSurface : AppColors.premiumDarkSurface;
    final textColor = isLight ? AppColors.lightTextPrimary : AppColors.premiumDarkTextPrimary;

    return InkWell(
      onTap: () => context.push('/customer/product', extra: product),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor, 
          borderRadius: BorderRadius.circular(20),
          boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)] : null,
          border: isLight ? Border.all(color: AppColors.lightBorder) : Border.all(color: AppColors.premiumDarkDivider.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(product.imageUrl, width: 64, height: 64, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name, 
                    style: TextStyle(
                      fontWeight: FontWeight.w800, 
                      fontSize: 14, 
                      color: textColor
                    ), 
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rs ${product.price.round()}', 
                    style: TextStyle(
                      color: primaryColor, 
                      fontWeight: FontWeight.w900, 
                      fontSize: 15
                    )
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

class _NearbyShopsGrid extends ConsumerWidget {
  const _NearbyShopsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nearbyAsync = ref.watch(nearbyShopsProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final primaryColor = isLight ? AppColors.lightPrimary : AppColors.premiumDarkPrimary;

    return nearbyAsync.when(
      data: (shops) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _ShopCard(shop: shops[index]),
            childCount: shops.length,
          ),
        ),
      ),
      loading: () => SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: primaryColor))),
      error: (e, s) => const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }
}

class _ShopCard extends StatelessWidget {
  final ShopModel shop;
  const _ShopCard({required this.shop});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final primaryColor = isLight ? AppColors.lightPrimary : AppColors.premiumDarkPrimary;
    final cardColor = isLight ? AppColors.lightSurface : AppColors.premiumDarkSurface;
    final textColor = isLight ? AppColors.lightTextPrimary : AppColors.premiumDarkTextPrimary;
    final secondaryTextColor = isLight ? AppColors.lightTextSecondary : AppColors.premiumDarkTextSecondary;

    return InkWell(
      onTap: () => context.push('/customer/shop/${shop.id}'),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor, 
          borderRadius: BorderRadius.circular(22),
          boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)] : null,
          border: isLight ? Border.all(color: AppColors.lightBorder) : Border.all(color: AppColors.premiumDarkDivider.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                child: shop.imageUrl.isNotEmpty 
                    ? Image.network(shop.imageUrl, fit: BoxFit.cover, width: double.infinity)
                    : Container(color: isLight ? AppColors.lightSecondaryBackground : AppColors.premiumDarkSecondaryBackground, child: Center(child: Icon(Icons.storefront, color: textColor.withOpacity(0.1)))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.name, 
                    style: TextStyle(
                      fontWeight: FontWeight.w800, 
                      fontSize: 13, 
                      color: textColor
                    ), 
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        shop.hasFreeDelivery ? 'FREE' : 'Rs ${shop.deliveryFee.round()}', 
                        style: TextStyle(
                          color: primaryColor, 
                          fontSize: 10, 
                          fontWeight: FontWeight.w900
                        )
                      ),
                      Icon(Icons.arrow_forward_rounded, size: 12, color: secondaryTextColor.withOpacity(0.3)),
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

class _GlassBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _GlassBadge({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const _Skeleton({this.width, required this.height, required this.radius});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isLight ? AppColors.lightSurface : AppColors.premiumDarkSurface,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

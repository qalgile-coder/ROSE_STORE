import 'dart:async';
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

final realTimeProductsStreamProvider = StreamProvider.autoDispose<List<ProductModel>>((ref) {
  return ref.watch(customerServiceProvider).getProductsStream();
});

String getCategoryArabicName(String categoryKey) {
  final Map<String, String> categoryNames = {
    'mens_clothing': 'ملابس رجالية',
    'womens_clothing': 'ملابس نسائية',
    'accessories': 'إكسسوارات',
    'cosmetics': 'مستحضرات تجميل',
    'mens_shoes': 'أحذية رجالية',
    'womens_shoes': 'أحذية نسائية',
    'kids_clothing': 'ملابس أطفال',
    'bags_wallets': 'حقائب ومحافظ',
    'perfumes': 'عطور',
  };
  return categoryNames[categoryKey.toLowerCase().trim()] ?? categoryKey;
}

class CustomerHome extends ConsumerWidget {
  const CustomerHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final connectivity = ref.watch(connectivityProvider).asData?.value;
    final isOffline = connectivity == ConnectivityResult.none;

    final bgColor = isLight ? AppColors.lightBackground : AppColors.premiumDarkBackground;
    final primaryColor = isLight ? AppColors.lightPrimary : AppColors.premiumDarkPrimary;
    final textColor = isLight ? AppColors.lightTextPrimary : AppColors.premiumDarkTextPrimary;
    
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Positioned(
            top: -150,
            left: -50,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [primaryColor.withValues(alpha: isLight ? 0.15 : 0.1), Colors.transparent],
                ),
              ),
            ),
          ),
          
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 180,
                floating: true,
                pinned: true,
                elevation: 0,
                backgroundColor: bgColor.withOpacity(0.85),
                flexibleSpace: FlexibleSpaceBar(
                  background: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(color: Colors.transparent),
                  ),
                ),
                title: Column(
                  children: [
                    _LocationHeader(ref: ref),
                    const SizedBox(height: 8),
                    // شعار ROSE في الأعلى مثل الصورة
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_florist_rounded, color: primaryColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'ROSE',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'YOUR STYLE. YOUR WORLD.',
                      style: TextStyle(
                        color: textColor.withOpacity(0.5),
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(80),
                  child: Column(
                    children: [
                      if (isOffline)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          color: AppColors.error.withOpacity(0.9),
                          child: const Center(
                            child: Text(
                              'WORKING OFFLINE • VIEWING CACHED DATA',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                            ),
                          ),
                        ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 5, 20, 15),
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
                      // سلايدر البنر الترويجي العلوي تماماً مثل الصورة
                      const _TopPromoBannerCard(),
                      const SizedBox(height: 24),
                      const _CategoryGrid(),
                      const SizedBox(height: 24),
                      // قائمة التصنيفات السريعة الأفقية (New In, Men, Women, Beauty, Accessories)
                      const _SubCategoriesBannerList(),
                      const SizedBox(height: 24),
                      // بنر عروض لفترة محدودة Flash Offers
                      const _FlashOffersBanner(),
                      const SizedBox(height: 32),
                      _SectionHeader(
                        title: 'متاجر مميزة', 
                        showSeeAll: true,
                        onSeeAll: '/customer/featured-shops',
                        textColor: textColor,
                        primaryColor: primaryColor,
                      ),
                      const SizedBox(height: 16),
                      const _FeaturedShops(),
                      const SizedBox(height: 32),
                      _SectionHeader(
                        title: 'الأكثر رواجا', 
                        showSeeAll: true, 
                        onSeeAll: '/customer/trending-products',
                        textColor: textColor, 
                        primaryColor: primaryColor
                      ),
                      const SizedBox(height: 16),
                      const _TrendingProducts(),
                      const SizedBox(height: 24),
                      _SectionHeader(
                        title: 'جميع المنتجات', 
                        showSeeAll: true, 
                        onSeeAll: '/customer/all-products',
                        textColor: textColor, 
                        primaryColor: primaryColor
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              const _AllMerchantProductsGridList(),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomerBottomNav(currentIndex: 0),
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
                Icon(Icons.location_on_rounded, color: primaryColor, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    defaultAddress?.fullAddress ?? 'الخرطوم',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textColor),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: textColor.withOpacity(0.5)),
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
        const SizedBox(width: 8),
        _HeaderActionBtn(
          icon: Icons.favorite_border_rounded, 
          onTap: () => context.push('/customer/wishlist'),
          cardColor: cardColor,
          textColor: textColor,
          isLight: isLight,
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => context.push('/customer/profile'),
          child: CircleAvatar(
            radius: 14,
            backgroundColor: cardColor,
            backgroundImage: (user?.profilePicture != null && user!.profilePicture!.isNotEmpty)
                ? NetworkImage(user.profilePicture!)
                : null,
            child: (user?.profilePicture == null || user!.profilePicture!.isEmpty)
                ? Text(
                    user?.name.substring(0, 1).toUpperCase() ?? '?',
                    style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold),
                  )
                : null,
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
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isLight ? AppColors.lightBorder : AppColors.premiumDarkDivider, width: 1),
        ),
        child: Icon(icon, color: textColor, size: 16),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final primaryColor = isLight ? AppColors.lightPrimary : AppColors.premiumDarkPrimary;
    final cardColor = isLight ? AppColors.lightSurface : AppColors.premiumDarkSurface;
    final secondaryTextColor = isLight ? AppColors.lightTextSecondary : AppColors.premiumDarkTextSecondary;

    return GestureDetector(
      onTap: () => context.push('/customer/search'),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isLight ? primaryColor.withOpacity(0.2) : AppColors.premiumDarkDivider.withOpacity(0.5), width: 1.2),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: primaryColor, size: 20),
            const SizedBox(width: 12),
            Text(
              'ابحث عن منتج، ماركة أو متجر...',
              style: TextStyle(color: secondaryTextColor.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Icon(Icons.tune_rounded, color: primaryColor, size: 18),
          ],
        ),
      ),
    );
  }
}

class _TopPromoBannerCard extends StatelessWidget {
  const _TopPromoBannerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?q=80&w=600'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [Colors.black.withOpacity(0.8), Colors.black.withOpacity(0.3), Colors.transparent],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'تألقي بإطلالتك',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const Text(
              'مع مجموعة ROSE الجديدة',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'أزياء، جمال، إكسسوارات وأكثر...',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.push('/customer/all-products'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size(100, 36),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('تسوق الآن', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid();

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final secondaryTextColor = isLight ? AppColors.lightTextSecondary : AppColors.premiumDarkTextSecondary;

    final categories = [
      {'name': 'رجالية', 'key': 'mens_clothing', 'icon': Icons.man_rounded},
      {'name': 'نسائية', 'key': 'womens_clothing', 'icon': Icons.woman_rounded},
      {'name': 'أطفال', 'key': 'kids_clothing', 'icon': Icons.child_care_rounded},
      {'name': 'مستحضرات تجميل', 'key': 'cosmetics', 'icon': Icons.face_retouching_natural_rounded},
      {'name': 'أحذية', 'key': 'mens_shoes', 'icon': Icons.roller_skating_rounded},
      {'name': 'حقائب', 'key': 'bags_wallets', 'icon': Icons.shopping_bag_rounded},
      {'name': 'إكسسوارات', 'key': 'accessories', 'icon': Icons.watch_rounded},
      {'name': 'عطور', 'key': 'perfumes', 'icon': Icons.propane_tank_rounded},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: categories.map((cat) {
          return Padding(
            padding: const EdgeInsets.only(left: 14),
            child: InkWell(
              onTap: () => context.push('/customer/category/${cat['key']}'),
              borderRadius: BorderRadius.circular(20),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isLight ? Colors.white : const Color(0xFF1E293B),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Icon(cat['icon'] as IconData, color: Colors.pinkAccent, size: 24),
                  ),
                  const SizedBox(height: 6),
                  Text(cat['name'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: secondaryTextColor)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SubCategoriesBannerList extends StatelessWidget {
  const _SubCategoriesBannerList();

  @override
  Widget build(BuildContext context) {
    final items = [
      {'title': 'وصل حديثاً', 'subtitle': 'NEW IN', 'img': 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?q=80&w=400', 'route': '/customer/category/mens_clothing'},
      {'title': 'رجالي', 'subtitle': 'MEN', 'img': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=400', 'route': '/customer/category/mens_clothing'},
      {'title': 'نسائي', 'subtitle': 'WOMEN', 'img': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=400', 'route': '/customer/category/womens_clothing'},
      {'title': 'جمال', 'subtitle': 'BEAUTY', 'img': 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?q=80&w=400', 'route': '/customer/category/cosmetics'},
      {'title': 'إكسسوارات', 'subtitle': 'ACCESSORIES', 'img': 'https://images.unsplash.com/photo-1523293182086-7651a899d37f?q=80&w=400', 'route': '/customer/category/accessories'},
    ];

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            onTap: () => context.push(item['route']!),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(image: NetworkImage(item['img']!), fit: BoxFit.cover),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                padding: const EdgeInsets.all(10),
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item['title']!, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    Text(item['subtitle']!, style: const TextStyle(color: Colors.white70, fontSize: 8)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FlashOffersBanner extends StatelessWidget {
  const _FlashOffersBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF4A154B), Color(0xFF1E1B4B)],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Row(
                children: [
                  Icon(Icons.flash_on_rounded, color: Colors.amber, size: 16),
                  SizedBox(width: 4),
                  Text('FLASH OFFERS', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              const Text('عروض لفترة محدودة', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => context.push('/customer/all-products'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54),
                  minimumSize: const Size(80, 28),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('اكتشف الآن', style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
            ],
          ),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('حتى', style: TextStyle(color: Colors.white70, fontSize: 10)),
              Text('70%', style: TextStyle(color: Colors.pinkAccent, fontSize: 24, fontWeight: FontWeight.w900)),
              Text('خصم', style: TextStyle(color: Colors.white70, fontSize: 10)),
            ],
          ),
        ],
      ),
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
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textColor)),
        if (showSeeAll)
          TextButton(
            onPressed: () {
              if (onSeeAll != null) context.push(onSeeAll!);
            },
            child: Text('عرض الكل', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w800, fontSize: 11)),
          ),
      ],
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
        if (shops.isEmpty) {
          // عرض متاجر بديلة افتراضية (نسائية، رجالية، أحذية) لتطابق التصميم بدقة
          final customShops = [
            {'name': 'متجر نسائي', 'route': '/customer/category/womens_clothing', 'img': 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?q=80&w=400'},
            {'name': 'متجر رجالي', 'route': '/customer/category/mens_clothing', 'img': 'https://images.unsplash.com/photo-1472851294608-062f824d29cc?q=80&w=400'},
            {'name': 'متجر أحذية', 'route': '/customer/category/mens_shoes', 'img': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?q=80&w=400'},
          ];
          return SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: customShops.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final shop = customShops[index];
                return InkWell(
                  onTap: () => context.push(shop['route']!),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(image: NetworkImage(shop['img']!), fit: BoxFit.cover),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.black.withOpacity(0.4),
                      ),
                      alignment: Alignment.center,
                      child: Text(shop['name']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                );
              },
            ),
          );
        }
        return SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: shops.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final shop = shops[index];
              return InkWell(
                onTap: () => context.push('/customer/shop/${shop.id}'),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: shop.imageUrl.isNotEmpty ? DecorationImage(image: NetworkImage(shop.imageUrl), fit: BoxFit.cover) : null,
                  ),
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.black54,
                    child: Text(shop.name, style: const TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }
}

class _TrendingProducts extends ConsumerWidget {
  const _TrendingProducts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingAsync = ref.watch(trendingProductsProvider);

    return trendingAsync.when(
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => SizedBox(
              width: 150,
              child: _GridProductCard(product: products[index]),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }
}

class _AllMerchantProductsGridList extends ConsumerWidget {
  const _AllMerchantProductsGridList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allProductsAsync = ref.watch(realTimeProductsStreamProvider);  

    return allProductsAsync.when(
      data: (products) {
        if (products.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _GridProductCard(product: products[index]);
              },
              childCount: products.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
      error: (e, s) => const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }
}

class _GridProductCard extends StatelessWidget {
  final ProductModel product;
  const _GridProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cardColor = isLight ? AppColors.lightSurface : AppColors.premiumDarkSurface;
    final textColor = isLight ? AppColors.lightTextPrimary : AppColors.premiumDarkTextPrimary;
    final primaryColor = isLight ? AppColors.lightPrimary : AppColors.premiumDarkPrimary;

    return InkWell(
      onTap: () => context.push('/customer/product', extra: product),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isLight ? AppColors.lightBorder : AppColors.premiumDarkDivider.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: product.imageUrl.isNotEmpty
                    ? Image.network(product.imageUrl, fit: BoxFit.cover, width: double.infinity)
                    : Container(color: Colors.grey.shade800),
              ),
            ),
            const SizedBox(height: 8),
            Text(product.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textColor), maxLines: 1),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${product.price.round()} ${product.currency}', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                const Icon(Icons.favorite_border_rounded, size: 16, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
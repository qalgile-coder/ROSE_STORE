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
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // رأس الصفحة الاحترافي الفاخر
              SliverAppBar(
                floating: true,
                pinned: true,
                elevation: 0,
                backgroundColor: bgColor.withOpacity(0.95),
                automaticallyImplyLeading: false,
                toolbarHeight: 65,
                title: const _TopHeaderBar(),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Column(
                    children: [
                      if (isOffline)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          color: AppColors.error,
                          child: const Center(
                            child: Text(
                              'WORKING OFFLINE • VIEWING CACHED DATA',
                              style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: _SearchBar(),
                      ),
                    ],
                  ),
                ),
              ),
              
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      // البنر الترويجي العلوي الراقي
                      const _TopPromoBannerCard(),
                      const SizedBox(height: 26),
                      
                      // عنوان الأقسام
                      Row(
                        mainAxisAlignment: MainAxisAlignment.between,
                        children: [
                          Text(
                            'الأقسام الرئيسية',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor, letterSpacing: 0.5),
                          ),
                          Text(
                            'عرض الكل',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFE91E63)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      
                      // الأقسام الاحترافية مع صور ملونة حقيقية
                      const _CategoryGrid(),
                      const SizedBox(height: 26),
                      
                      // التصنيفات السريعة الأفقية
                      const _SubCategoriesBannerList(),
                      const SizedBox(height: 26),
                      
                      // بنر عروض لفترة محدودة
                      const _FlashOffersBanner(),
                      const SizedBox(height: 28),
                      
                      _SectionHeader(
                        title: 'متاجر مميزة', 
                        showSeeAll: true,
                        onSeeAll: '/customer/featured-shops',
                        textColor: textColor,
                        primaryColor: primaryColor,
                      ),
                      const SizedBox(height: 14),
                      const _FeaturedShops(),
                      const SizedBox(height: 28),
                      
                      _SectionHeader(
                        title: 'الأكثر رواجاً', 
                        showSeeAll: true, 
                        onSeeAll: '/customer/trending-products',
                        textColor: textColor, 
                        primaryColor: primaryColor,
                      ),
                      const SizedBox(height: 14),
                      const _TrendingProducts(),
                      const SizedBox(height: 24),
                      
                      _SectionHeader(
                        title: 'جميع المنتجات', 
                        showSeeAll: true, 
                        onSeeAll: '/customer/all-products',
                        textColor: textColor, 
                        primaryColor: primaryColor,
                      ),
                      const SizedBox(height: 14),
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

// هيدر علوي منظم ومصمم بعناية فائقة يضاهي التطبيقات العالمية
class _TopHeaderBar extends ConsumerWidget {
  const _TopHeaderBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defaultAddress = ref.watch(defaultAddressProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textColor = isLight ? AppColors.lightTextPrimary : AppColors.premiumDarkTextPrimary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // الموقع الجغرافي على الطرف الأيمن بتصميم راقي
        InkWell(
          onTap: () => context.push('/customer/addresses'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isLight ? Colors.grey.shade100 : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isLight ? Colors.grey.shade300 : Colors.white10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_rounded, color: Color(0xFFE91E63), size: 16),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 85),
                  child: Text(
                    defaultAddress?.fullAddress ?? 'الخرطوم',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Colors.grey),
              ],
            ),
          ),
        ),

        // الأقسام التفاعلية والإشعارات والمفضلة على الطرف الآخر
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HeaderActionBtn(
              icon: Icons.notifications_none_rounded, 
              badgeCount: 3,
              onTap: () => context.push('/customer/notifications'),
            ),
            const SizedBox(width: 10),
            _HeaderActionBtn(
              icon: Icons.favorite_border_rounded, 
              onTap: () => context.push('/customer/wishlist'),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int? badgeCount;
  const _HeaderActionBtn({required this.icon, required this.onTap, this.badgeCount});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: isLight ? Colors.grey.shade100 : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isLight ? Colors.grey.shade300 : Colors.white10),
            ),
            child: Icon(icon, size: 20, color: isLight ? Colors.black87 : Colors.white),
          ),
        ),
        if (badgeCount != null && badgeCount! > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFFE91E63),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Center(
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return GestureDetector(
      onTap: () => context.push('/customer/search'),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isLight ? Colors.white : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (isLight)
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
          ],
          border: Border.all(color: isLight ? Colors.grey.shade300 : Colors.white12, width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: Color(0xFFE91E63), size: 22),
            const SizedBox(width: 12),
            Text(
              'ابحث عن منتج، ماركة أو متجر...',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFE91E63).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.tune_rounded, color: Color(0xFFE91E63), size: 18),
            ),
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
      height: 165,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?q=80&w=600'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
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
              style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'أزياء، جمال، إكسسوارات وأكثر...',
              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () => context.push('/customer/all-products'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size(100, 34),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('تسوق الآن', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
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
    final textColor = isLight ? AppColors.lightTextPrimary : AppColors.premiumDarkTextPrimary;

    final categories = [
      {'name': 'رجالية', 'key': 'mens_clothing', 'img': 'https://images.unsplash.com/photo-1617137984095-74e4e5e3613f?q=80&w=300'},
      {'name': 'نسائية', 'key': 'womens_clothing', 'img': 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?q=80&w=300'},
      {'name': 'أطفال', 'key': 'kids_clothing', 'img': 'https://images.unsplash.com/photo-1519457431-44ccd64a579b?q=80&w=300'},
      {'name': 'تجميل', 'key': 'cosmetics', 'img': 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?q=80&w=300'},
      {'name': 'أحذية', 'key': 'mens_shoes', 'img': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?q=80&w=300'},
      {'name': 'حقائب', 'key': 'bags_wallets', 'img': 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?q=80&w=300'},
      {'name': 'إكسسوارات', 'key': 'accessories', 'img': 'https://images.unsplash.com/photo-1523293182086-7651a899d37f?q=80&w=300'},
      {'name': 'عطور', 'key': 'perfumes', 'img': 'https://images.unsplash.com/photo-1523293182086-7651a899d37f?q=80&w=300'},
    ];

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return InkWell(
            onTap: () => context.push('/customer/category/${cat['key']}'),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE91E63).withOpacity(0.4), width: 2),
                    image: DecorationImage(
                      image: NetworkImage(cat['img']!),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 3)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  cat['name'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11, 
                    fontWeight: FontWeight.bold, 
                    color: textColor,
                  ),
                ),
              ],
            ),
          );
        },
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
      height: 115,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            onTap: () => context.push(item['route']!),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 105,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                image: DecorationImage(image: NetworkImage(item['img']!), fit: BoxFit.cover),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.75), Colors.transparent],
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
      height: 105,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF311026), Color(0xFF1E1B4B)],
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
                  Icon(Icons.flash_on_rounded, color: Colors.amber, size: 15),
                  SizedBox(width: 4),
                  Text('FLASH OFFERS', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 2),
              const Text('عروض لفترة محدودة', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              OutlinedButton(
                onPressed: () => context.push('/customer/all-products'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white38),
                  minimumSize: const Size(75, 28),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('اكتشف', style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
            ],
          ),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('حتى', style: TextStyle(color: Colors.white60, fontSize: 9)),
              Text('70%', style: TextStyle(color: Color(0xFFE91E63), fontSize: 24, fontWeight: FontWeight.w900)),
              Text('خصم', style: TextStyle(color: Colors.white60, fontSize: 9)),
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
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
        if (showSeeAll)
          TextButton(
            onPressed: () {
              if (onSeeAll != null) context.push(onSeeAll!);
            },
            child: const Text('عرض الكل', style: TextStyle(color: Color(0xFFE91E63), fontWeight: FontWeight.bold, fontSize: 12)),
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
          // تم تغيير الأسماء لتكون مخصصة ومصنفة (رجالي، نسائي، أطفال، عطور وإكسسوارات)
          final customShops = [
            {'name': 'أزياء رجالية', 'route': '/customer/category/mens_clothing', 'img': 'https://images.unsplash.com/photo-1617137984095-74e4e5e3613f?q=80&w=400'},
            {'name': 'أزياء نسائية', 'route': '/customer/category/womens_clothing', 'img': 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?q=80&w=400'},
            {'name': 'ملابس أطفال', 'route': '/customer/category/kids_clothing', 'img': 'https://images.unsplash.com/photo-1519457431-44ccd64a579b?q=80&w=400'},
            {'name': 'عطور وإكسسوارات', 'route': '/customer/category/accessories', 'img': 'https://images.unsplash.com/photo-1523293182086-7651a899d37f?q=80&w=400'},
          ];
          return SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: customShops.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final shop = customShops[index];
                return InkWell(
                  onTap: () => context.push(shop['route']!),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      image: DecorationImage(image: NetworkImage(shop['img']!), fit: BoxFit.cover),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                      alignment: Alignment.bottomCenter,
                      padding: const EdgeInsets.all(8),
                      child: Text(shop['name']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ),
                );
              },
            ),
          );
        }
        return SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: shops.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final shop = shops[index];
              return InkWell(
                onTap: () => context.push('/customer/shop/${shop.id}'),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
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
              width: 145,
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
    final cardColor = isLight ? Colors.white : const Color(0xFF1E293B);
    final textColor = isLight ? AppColors.lightTextPrimary : AppColors.premiumDarkTextPrimary;

    return InkWell(
      onTap: () => context.push('/customer/product', extra: product),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isLight ? Colors.grey.shade200 : Colors.white10),
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
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${product.price.round()} ${product.currency}', style: const TextStyle(color: Color(0xFFE91E63), fontWeight: FontWeight.bold, fontSize: 12)),
                const Icon(Icons.favorite_border_rounded, size: 16, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
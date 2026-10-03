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
              // رأس الصفحة الاحترافي المطابق للصورة تماماً
              SliverAppBar(
                floating: true,
                pinned: true,
                elevation: 0,
                backgroundColor: bgColor.withOpacity(0.92),
                automaticallyImplyLeading: false,
                title: _TopHeaderBar(ref: ref),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(65),
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
                      // البنر الترويجي العلوي
                      const _TopPromoBannerCard(),
                      const SizedBox(height: 24),
                      
                      // عنوان الأقسام
                      const Text(
                        'الأقسام الرئيسية',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      
                      // الأقسام الدائرية الاحترافية الجديدة
                      const _CategoryGrid(),
                      const SizedBox(height: 24),
                      
                      // التصنيفات السريعة الأفقية
                      const _SubCategoriesBannerList(),
                      const SizedBox(height: 24),
                      
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

// شريط العنوان العلوي المطابق للصورة (اللوكيشن يمين والأيقونات يسار، وبدون شعار)
class _TopHeaderBar extends StatelessWidget {
  final WidgetRef ref;
  const _TopHeaderBar({required this.ref});

  @override
  Widget build(BuildContext context) {
    final defaultAddress = ref.watch(defaultAddressProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textColor = isLight ? AppColors.lightTextPrimary : AppColors.premiumDarkTextPrimary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // الجهة اليمين: معلومات التوصيل واللوكيشن
        Expanded(
          child: InkWell(
            onTap: () => context.push('/customer/addresses'),
            borderRadius: BorderRadius.circular(10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_rounded, color: Color(0xFFE91E63), size: 20),
                const SizedBox(width: 4),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'التوصيل إلى',
                        style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        defaultAddress?.fullAddress ?? 'جبرة',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),

        // الجهة اليسار: أيقونات التفاعل (بحث، مفضلة، إشعارات)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HeaderActionBtn(
              icon: Icons.search_rounded, 
              onTap: () => context.push('/customer/search'),
            ),
            const SizedBox(width: 8),
            _HeaderActionBtn(
              icon: Icons.favorite_border_rounded, 
              onTap: () => context.push('/customer/wishlist'),
            ),
            const SizedBox(width: 8),
            _HeaderActionBtn(
              icon: Icons.notifications_none_rounded, 
              onTap: () => context.push('/customer/notifications'),
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
  const _HeaderActionBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isLight ? Colors.grey.shade100 : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isLight ? Colors.grey.shade300 : Colors.white10),
        ),
        child: Icon(icon, size: 18, color: isLight ? Colors.black87 : Colors.white),
      ),
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
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isLight ? Colors.white : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isLight ? Colors.grey.shade300 : Colors.white12, width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: Color(0xFFE91E63), size: 20),
            const SizedBox(width: 10),
            Text(
              'ابحث عما ترغب فيه اليوم...',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Icon(Icons.tune_rounded, color: Colors.grey.shade400, size: 18),
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
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?q=80&w=600'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.black.withOpacity(0.75), Colors.black.withOpacity(0.2), Colors.transparent],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'تألقي بإطلالتك',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'مع مجموعة ROSE الجديدة',
              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.push('/customer/all-products'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size(90, 32),
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

// الأقسام الدائرية الاحترافية
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid();

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textColor = isLight ? AppColors.lightTextPrimary : AppColors.premiumDarkTextPrimary;

    final categories = [
      {'name': 'رجالية', 'key': 'mens_clothing', 'icon': Icons.man_rounded},
      {'name': 'نسائية', 'key': 'womens_clothing', 'icon': Icons.woman_rounded},
      {'name': 'أطفال', 'key': 'kids_clothing', 'icon': Icons.child_care_rounded},
      {'name': 'تجميل', 'key': 'cosmetics', 'icon': Icons.face_retouching_natural_rounded},
      {'name': 'أحذية', 'key': 'mens_shoes', 'icon': Icons.roller_skating_rounded},
      {'name': 'حقائب', 'key': 'bags_wallets', 'icon': Icons.shopping_bag_rounded},
      {'name': 'إكسسوارات', 'key': 'accessories', 'icon': Icons.watch_rounded},
      {'name': 'عطور', 'key': 'perfumes', 'icon': Icons.local_florist_rounded},
    ];

    return SizedBox(
      height: 95,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return InkWell(
            onTap: () => context.push('/customer/category/${cat['key']}'),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63).withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE91E63).withOpacity(0.3), width: 1.5),
                  ),
                  child: Icon(cat['icon'] as IconData, color: const Color(0xFFE91E63), size: 26),
                ),
                const SizedBox(height: 6),
                Text(
                  cat['name'] as String,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textColor),
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
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            onTap: () => context.push(item['route']!),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(image: NetworkImage(item['img']!), fit: BoxFit.cover),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                padding: const EdgeInsets.all(8),
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item['title']!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text(item['subtitle']!, style: const TextStyle(color: Colors.white70, fontSize: 7)),
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
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF311026), Color(0xFF1E1B4B)],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Row(
                children: [
                  Icon(Icons.flash_on_rounded, color: Colors.amber, size: 14),
                  SizedBox(width: 4),
                  Text('FLASH OFFERS', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 2),
              const Text('عروض لفترة محدودة', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              OutlinedButton(
                onPressed: () => context.push('/customer/all-products'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white38),
                  minimumSize: const Size(70, 26),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('اكتشف', style: TextStyle(color: Colors.white, fontSize: 9)),
              ),
            ],
          ),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('حتى', style: TextStyle(color: Colors.white60, fontSize: 9)),
              Text('70%', style: TextStyle(color: Color(0xFFE91E63), fontSize: 22, fontWeight: FontWeight.w900)),
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
        Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
        if (showSeeAll)
          TextButton(
            onPressed: () {
              if (onSeeAll != null) context.push(onSeeAll!);
            },
            child: const Text('عرض الكل', style: TextStyle(color: Color(0xFFE91E63), fontWeight: FontWeight.bold, fontSize: 11)),
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
          final customShops = [
            {'name': 'متجر نسائي', 'route': '/customer/category/womens_clothing', 'img': 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?q=80&w=400'},
            {'name': 'متجر رجالي', 'route': '/customer/category/mens_clothing', 'img': 'https://images.unsplash.com/photo-1472851294608-062f824d29cc?q=80&w=400'},
            {'name': 'متجر أحذية', 'route': '/customer/category/mens_shoes', 'img': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?q=80&w=400'},
          ];
          return SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: customShops.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final shop = customShops[index];
                return InkWell(
                  onTap: () => context.push(shop['route']!),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 115,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(image: NetworkImage(shop['img']!), fit: BoxFit.cover),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.black.withOpacity(0.45),
                      ),
                      alignment: Alignment.center,
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
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final shop = shops[index];
              return InkWell(
                onTap: () => context.push('/customer/shop/${shop.id}'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 115,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: shop.imageUrl.isNotEmpty ? DecorationImage(image: NetworkImage(shop.imageUrl), fit: BoxFit.cover) : null,
                  ),
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    color: Colors.black54,
                    child: Text(shop.name, style: const TextStyle(color: Colors.white, fontSize: 10)),
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
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) => SizedBox(
              width: 140,
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
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.75,
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isLight ? Colors.grey.shade200 : Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: product.imageUrl.isNotEmpty
                    ? Image.network(product.imageUrl, fit: BoxFit.cover, width: double.infinity)
                    : Container(color: Colors.grey.shade800),
              ),
            ),
            const SizedBox(height: 6),
            Text(product.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: textColor), maxLines: 1),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${product.price.round()} ${product.currency}', style: const TextStyle(color: Color(0xFFE91E63), fontWeight: FontWeight.bold, fontSize: 11)),
                const Icon(Icons.favorite_border_rounded, size: 14, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
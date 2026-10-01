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

// دالة تحويل الكود الإنجليزي للأقسام إلى الاسم العربي المناسب[cite: 10]
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

    // Dynamic Theme Mapping[cite: 10]
    final bgColor = isLight ? AppColors.lightBackground : AppColors.premiumDarkBackground;
    final primaryColor = isLight ? AppColors.lightPrimary : AppColors.premiumDarkPrimary;
    final textColor = isLight ? AppColors.lightTextPrimary : AppColors.premiumDarkTextPrimary;
    
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background Gradient Glow[cite: 10]
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
                expandedHeight: 160,
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
                title: _LocationHeader(ref: ref),
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
                      _SectionHeader(title: 'الأقسام الرئيسية', showSeeAll: false, textColor: textColor, primaryColor: primaryColor),
                      const SizedBox(height: 16),
                      const _CategoryGrid(),
                      const SizedBox(height: 24),
                      // سلايدر البنرات الترويجية[cite: 10]
                      const _PromoBannersSlider(),
                      const SizedBox(height: 32),
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
              // قسم جميع المنتجات[cite: 10]
              const _AllMerchantProductsGridList(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      _SectionHeader(
                        title: 'المتاجر المميزة', 
                        showSeeAll: true,
                        onSeeAll: '/customer/featured-shops',
                        textColor: textColor,
                        primaryColor: primaryColor,
                      ),
                      const SizedBox(height: 16),
                      const _FeaturedShops(),
                      const SizedBox(height: 32),
                      _SectionHeader(
                        title: 'المنتجات الرائجة', 
                        showSeeAll: true, 
                        onSeeAll: '/customer/trending-products',
                        textColor: textColor, 
                        primaryColor: primaryColor
                      ),
                      const SizedBox(height: 16),
                      const _TrendingProducts(),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          
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
                    gradient: LinearGradient(colors: [primaryColor.withOpacity(0.2), primaryColor.withOpacity(0.05)]),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: primaryColor.withOpacity(0.2)),
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
                        'التوصيل إلى',
                        style: TextStyle(
                          color: primaryColor.withOpacity(0.9),
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
                              defaultAddress?.fullAddress ?? 'اختر موقع التوصيل',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: textColor.withOpacity(0.5)),
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
        const SizedBox(width: 10),
        _HeaderActionBtn(
          icon: Icons.favorite_border_rounded, 
          onTap: () => context.push('/customer/wishlist'),
          cardColor: cardColor,
          textColor: textColor,
          isLight: isLight,
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => context.push('/customer/profile'),
          child: Hero(
            tag: 'profile_avatar',
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.3)]),
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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isLight ? AppColors.lightBorder : AppColors.premiumDarkDivider, width: 1.2),
          boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))] : null,
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
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: isLight ? primaryColor.withOpacity(0.08) : Colors.black.withOpacity(0.2), 
              blurRadius: 25, 
              offset: const Offset(0, 10)
            ),
          ],
          border: Border.all(color: isLight ? primaryColor.withOpacity(0.2) : AppColors.premiumDarkDivider.withOpacity(0.5), width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: primaryColor, size: 24),
            const SizedBox(width: 14),
            Text(
              'ابحث عما ترغب فيه اليوم...',
              style: TextStyle(color: secondaryTextColor.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [primaryColor.withOpacity(0.2), primaryColor.withOpacity(0.05)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.tune_rounded, color: primaryColor, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoBannersSlider extends ConsumerStatefulWidget {
  const _PromoBannersSlider();

  @override
  ConsumerState<_PromoBannersSlider> createState() => _PromoBannersSliderState();
}

class _PromoBannersSliderState extends ConsumerState<_PromoBannersSlider> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      final offersAsync = ref.read(activeOffersProvider);
      offersAsync.whenData((offers) {
        if (offers.length > 1 && _pageController.hasClients) {
          if (_currentIndex < offers.length - 1) {
            _currentIndex++;
          } else {
            _currentIndex = 0;
          }
          _pageController.animateToPage(
            _currentIndex,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offersAsync = ref.watch(activeOffersProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final primaryColor = isLight ? AppColors.lightPrimary : AppColors.premiumDarkPrimary;

    return offersAsync.when(
      data: (offers) {
        if (offers.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            SizedBox(
              height: 220,
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: offers.length,
                itemBuilder: (context, index) {
                  final offer = offers[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [
                        BoxShadow(
                          color: isLight ? primaryColor.withOpacity(0.22) : Colors.black.withOpacity(0.5), 
                          blurRadius: 40, 
                          offset: const Offset(0, 18)
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
                                  colors: [Colors.black.withOpacity(0.9), Colors.black.withOpacity(0.4), Colors.transparent],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 10)],
                                  ),
                                  child: Text(
                                    offer.offerType == 'percentage' ? '${offer.value.round()}% خصم حصري' : 'عرض مميز',
                                    style: TextStyle(color: isLight ? Colors.white : AppColors.premiumDarkBackground, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  offer.title,
                                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => context.push('/customer/offer', extra: offer),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    minimumSize: const Size(120, 44),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    shadowColor: Colors.black.withOpacity(0.2),
                                  ),
                                  child: const Text('تسوق الآن', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (offers.length > 1) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  offers.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == index ? primaryColor : primaryColor.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const _Skeleton(height: 220, radius: 36),
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
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.w900, 
                    color: textColor, 
                    letterSpacing: -0.5
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (showSeeAll)
          TextButton(
            onPressed: () {
              if (onSeeAll != null) {
                context.push(onSeeAll!);
              }
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('عرض الكل', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios_rounded, size: 10, color: primaryColor),
              ],
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

    final categories = [
      {'name': 'ملابس رجالية', 'key': 'mens_clothing', 'icon': Icons.man_rounded, 'color': const Color(0xFF3B82F6)},
      {'name': 'ملابس نسائية', 'key': 'womens_clothing', 'icon': Icons.woman_rounded, 'color': const Color(0xFFEC4899)},
      {'name': 'إكسسوارات', 'key': 'accessories', 'icon': Icons.watch_rounded, 'color': const Color(0xFF8B5CF6)},
      {'name': 'مستحضرات تجميل', 'key': 'cosmetics', 'icon': Icons.face_retouching_natural_rounded, 'color': const Color(0xFFF43F5E)},
      {'name': 'أحذية رجالية', 'key': 'mens_shoes', 'icon': Icons.roller_skating_rounded, 'color': const Color(0xFF6366F1)},
      {'name': 'أحذية نسائية', 'key': 'womens_shoes', 'icon': Icons.set_meal_rounded, 'color': const Color(0xFF14B8A6)},
      {'name': 'ملابس أطفال', 'key': 'kids_clothing', 'icon': Icons.child_care_rounded, 'color': const Color(0xFFEF4444)},
      {'name': 'حقائب ومحافظ', 'key': 'bags_wallets', 'icon': Icons.shopping_bag_rounded, 'color': const Color(0xFFF59E0B)},
      {'name': 'عطور', 'key': 'perfumes', 'icon': Icons.propane_tank_rounded, 'color': const Color(0xFF10B981)},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
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
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: color.withOpacity(0.3), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(isLight ? 0.15 : 0.08), 
                          blurRadius: 15, 
                          offset: const Offset(0, 6)
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(cat['icon'] as IconData, color: color, size: 28),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(cat['name'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: secondaryTextColor)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AllMerchantProductsGridList extends ConsumerWidget {
  const _AllMerchantProductsGridList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allProductsAsync = ref.watch(realTimeProductsStreamProvider);  
    final isLight = Theme.of(context).brightness == Brightness.light;
    final primaryColor = isLight ? AppColors.lightPrimary : AppColors.premiumDarkPrimary;

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
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.70,
            ),
          ),
        );
      },
      loading: () => SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: CircularProgressIndicator(color: primaryColor),
          ),
        ),
      ),
      error: (e, s) => const SliverToBoxAdapter(child: SizedBox.shrink()),
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

    return InkWell(
      onTap: () => context.push('/customer/product', extra: product),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor, 
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isLight ? Colors.black.withOpacity(0.05) : Colors.black.withOpacity(0.2), 
              blurRadius: 15, 
              offset: const Offset(0, 6)
            ),
          ],
          border: Border.all(
            color: isLight ? AppColors.lightBorder : AppColors.premiumDarkDivider.withOpacity(0.5), 
            width: 1.2
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: product.imageUrl.isNotEmpty 
                    ? Image.network(product.imageUrl, fit: BoxFit.cover, width: double.infinity)
                    : Container(
                        width: double.infinity, 
                        color: isLight ? AppColors.lightSecondaryBackground : AppColors.premiumDarkSecondaryBackground, 
                        child: Center(child: Icon(Icons.image_rounded, color: textColor.withOpacity(0.2), size: 30))
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              product.name, 
              style: TextStyle(
                fontWeight: FontWeight.w900, 
                fontSize: 13.5, 
                color: textColor
              ), 
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              getCategoryArabicName(product.category), 
              style: TextStyle(
                color: primaryColor, 
                fontSize: 11, 
                fontWeight: FontWeight.w800
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${product.price.round()} ${product.currency}', 
                  style: TextStyle(
                    color: primaryColor, 
                    fontWeight: FontWeight.w900, 
                    fontSize: 14
                  )
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.8)]),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                ),
              ],
            ),
          ],
        ),
      ),
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
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: shops.length,
            padding: const EdgeInsets.only(right: 20),
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) => _FeaturedShopCard(shop: shops[index]),
          ),
        );
      },
      loading: () => SizedBox(height: 250, child: ListView(scrollDirection: Axis.horizontal, children: List.generate(2, (_) => const Padding(padding: EdgeInsets.only(right: 16), child: _Skeleton(width: 270, height: 250, radius: 28))))),
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

    return InkWell(
      onTap: () => context.push('/customer/shop/${shop.id}'),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: isLight ? Colors.black.withOpacity(0.06) : Colors.black.withOpacity(0.25), 
              blurRadius: 24, 
              offset: const Offset(0, 10)
            )
          ],
          border: Border.all(color: isLight ? AppColors.lightBorder : AppColors.premiumDarkDivider.withOpacity(0.5), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  child: Hero(
                    tag: 'shop_home_${shop.id}',
                    child: shop.imageUrl.isNotEmpty 
                        ? Image.network(shop.imageUrl, height: 145, width: double.infinity, fit: BoxFit.cover)
                        : Container(height: 145, color: isLight ? AppColors.lightSecondaryBackground : AppColors.premiumDarkSecondaryBackground, child: Center(child: Icon(Icons.storefront_rounded, color: textColor.withOpacity(0.2), size: 45))),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: _GlassBadge(label: '${shop.rating}', icon: Icons.star_rounded, color: AppColors.warning),
                ),
                if (shop.hasFreeDelivery)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _GlassBadge(label: 'توصيل مجاني', icon: Icons.bolt_rounded, color: AppColors.success),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
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
                            fontSize: 16, 
                            color: textColor, 
                            letterSpacing: -0.2
                          ), 
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          shop.deliveryTime,
                          style: TextStyle(color: theme.colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                      ),
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
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
              ),
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
        color: isLight ? Colors.black.withOpacity(0.06) : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(radius),
      ),
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
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: products.length,
            padding: const EdgeInsets.only(right: 20),
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) => SizedBox(
              width: 160,
              child: _GridProductCard(product: products[index]),
            ),
          ),
        );
      },
      loading: () => SizedBox(height: 240, child: ListView(scrollDirection: Axis.horizontal, children: List.generate(2, (_) => const Padding(padding: EdgeInsets.only(right: 14), child: _Skeleton(width: 160, height: 240, radius: 24))))),
      error: (e, s) => const SizedBox.shrink(),
    );
  }
}
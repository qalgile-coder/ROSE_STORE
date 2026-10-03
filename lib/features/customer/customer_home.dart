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

// دالة تحويل الكود الإنجليزي للأقسام إلى الاسم العربي المناسب
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
                title: const _TopBrandHeader(),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(105),
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        child: Row(
                          children: [
                            const Expanded(child: _LocationHeaderWidget()),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 6, 20, 14),
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
                      // سلايدر البنرات الترويجية
                      const _PromoBannersSlider(),
                      const SizedBox(height: 24),
                      const _CategoryGrid(),
                      const SizedBox(height: 24),
                      // قسم الأقسام المربعة السريعة الجديدة تماماً مثل الصورة
                      const _QuickCategoriesBoxes(),
                      const SizedBox(height: 24),
                      // بانر عرض الفلاش المميز
                      const _FlashOffersBanner(),
                      const SizedBox(height: 28),
                      _SectionHeader(
                        title: 'متاجر مميزة', 
                        showSeeAll: true,
                        onSeeAll: '/customer/featured-shops',
                        textColor: textColor,
                        primaryColor: primaryColor,
                      ),
                      const SizedBox(height: 16),
                      const _FeaturedShops(),
                      const SizedBox(height: 28),
                      _SectionHeader(
                        title: 'الأكثر رواجاً', 
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
              // قسم جميع المنتجات
              const _AllMerchantProductsGridList(),
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

class _TopBrandHeader extends StatelessWidget {
  const _TopBrandHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final primaryColor = isLight ? AppColors.lightPrimary : AppColors.premiumDarkPrimary;
    final textColor = isLight ? AppColors.lightTextPrimary : AppColors.premiumDarkTextPrimary;
    final cardColor = isLight ? Colors.white : const Color(0xFF1E293B);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // زر الموقع (الخرطوم) في أعلى اليسار أو اليمين حسب التصميم
        Row(
          children: [
            InkWell(
              onTap: () => context.push('/customer/addresses'),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.location_on_rounded, color: primaryColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'الخرطوم',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: textColor.withOpacity(0.6)),
                  ],
                ),
              ),
            ),
          ],
        ),
        
        // شعار ROOZ في منتصف الهيدر تماماً مثل الصورة
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_florist, color: primaryColor, size: 16),
                const SizedBox(width: 4),
                Text(
                  'ROSE',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: textColor,
                  ),
                ),
              ],
            ),
            Text(
              'YOUR STYLE. YOUR WORLD.',
              style: TextStyle(
                fontSize: 7.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: textColor.withOpacity(0.6),
              ),
            ),
          ],
        ),

        // الأيقونات الثلاثة: إشعارات، مفضلة، بروفایل
        Row(
          children: [
            _HeaderActionBtn(
              icon: Icons.notifications_none_rounded, 
              badgeCount: '3',
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
              child: Hero(
                tag: 'profile_avatar',
                child: Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.3)]),
                  ),
                  child: const CircleAvatar(
                    radius: 14,
                    backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LocationHeaderWidget extends StatelessWidget {
  const _LocationHeaderWidget();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _HeaderActionBtn extends StatelessWidget {
  final IconData icon;
  final String? badgeCount;
  final VoidCallback onTap;
  final Color cardColor;
  final Color textColor;
  final bool isLight;
  const _HeaderActionBtn({required this.icon, this.badgeCount, required this.onTap, required this.cardColor, required this.textColor, required this.isLight});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isLight ? AppColors.lightBorder : AppColors.premiumDarkDivider, width: 1),
            ),
            child: Icon(icon, color: textColor, size: 18),
          ),
          if (badgeCount != null)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.pinkAccent,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                child: Center(
                  child: Text(
                    badgeCount!,
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
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
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: isLight ? primaryColor.withOpacity(0.06) : Colors.black.withOpacity(0.2), 
              blurRadius: 20, 
              offset: const Offset(0, 8)
            ),
          ],
          border: Border.all(color: isLight ? primaryColor.withOpacity(0.15) : AppColors.premiumDarkDivider.withOpacity(0.5), width: 1.2),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: primaryColor, size: 22),
            const SizedBox(width: 12),
            Text(
              'ابحث عن منتج، ماركة أو متجر...',
              style: TextStyle(color: secondaryTextColor.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [primaryColor.withOpacity(0.2), primaryColor.withOpacity(0.05)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.tune_rounded, color: primaryColor, size: 16),
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
        final displayOffers = offers.isEmpty ? [
          // Fallback banner matching the exact image mockup
          ShopModel(id: '1', name: 'ROSE', imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?q=80&w=800', rating: 5.0, deliveryTime: '20m', hasFreeDelivery: true)
        ] : offers;

        return Column(
          children: [
            SizedBox(
              height: 190,
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: displayOffers.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: isLight ? primaryColor.withOpacity(0.2) : Colors.black.withOpacity(0.5), 
                          blurRadius: 30, 
                          offset: const Offset(0, 12)
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.network(
                              'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?q=80&w=800',
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.black.withOpacity(0.85), Colors.black.withOpacity(0.3), Colors.transparent],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'تألقي بإطلالتك',
                                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'مع مجموعة ROSE الجديدة',
                                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'أزياء، جمال، إكسسوارات وأكثر...',
                                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 14),
                                ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    minimumSize: const Size(100, 36),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Text('تسوق الآن', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                                      SizedBox(width: 4),
                                      Icon(Icons.arrow_back_ios, size: 10, color: Colors.black),
                                    ],
                                  ),
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
          ],
        );
      },
      loading: () => const _Skeleton(height: 190, radius: 28),
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
        Text(
          title,
          style: TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.w900, 
            color: textColor, 
            letterSpacing: -0.5
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
              padding: EdgeInsets.zero,
              minimumSize: const Size(50, 24),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('عرض الكل', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w800, fontSize: 11)),
                const SizedBox(width: 2),
                Icon(Icons.arrow_forward_ios_rounded, size: 9, color: primaryColor),
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
      {'name': 'رجالية', 'key': 'mens_clothing', 'icon': Icons.man_rounded, 'color': const Color(0xFF3B82F6)},
      {'name': 'نسائية', 'key': 'womens_clothing', 'icon': Icons.woman_rounded, 'color': const Color(0xFFEC4899)},
      {'name': 'أطفال', 'key': 'kids_clothing', 'icon': Icons.child_care_rounded, 'color': const Color(0xFFEF4444)},
      {'name': 'مستحضرات تجميل', 'key': 'cosmetics', 'icon': Icons.face_retouching_natural_rounded, 'color': const Color(0xFFF43F5E)},
      {'name': 'أحذية', 'key': 'mens_shoes', 'icon': Icons.roller_skating_rounded, 'color': const Color(0xFF6366F1)},
      {'name': 'حقائب', 'key': 'bags_wallets', 'icon': Icons.shopping_bag_rounded, 'color': const Color(0xFFF59E0B)},
      {'name': 'إكسسوارات', 'key': 'accessories', 'icon': Icons.watch_rounded, 'color': const Color(0xFF8B5CF6)},
      {'name': 'عطور', 'key': 'perfumes', 'icon': Icons.propane_tank_rounded, 'color': const Color(0xFF10B981)},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: categories.map((cat) {
          final color = cat['color'] as Color;
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
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withOpacity(0.2), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.08), 
                          blurRadius: 10, 
                          offset: const Offset(0, 4)
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(cat['icon'] as IconData, color: color, size: 26),
                    ),
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

// قسم المربعات الكبيرة مثل الصورة (New In, Men, Women, Beauty, Accessories)
class _QuickCategoriesBoxes extends StatelessWidget {
  const _QuickCategoriesBoxes();

  @override
  Widget build(BuildContext context) {
    final items = [
      {'title': 'NEW IN', 'subtitle': 'وصل حديثاً', 'image': 'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?q=80&w=400'},
      {'title': 'MEN', 'subtitle': 'رجالي', 'image': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=400'},
      {'title': 'WOMEN', 'subtitle': 'نسائي', 'image': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=400'},
      {'title': 'BEAUTY', 'subtitle': 'جمال', 'image': 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?q=80&w=400'},
      {'title': 'ACCESSORIES', 'subtitle': 'إكسسوارات', 'image': 'https://images.unsplash.com/photo-1523293182086-7651a899d37f?q=80&w=400'},
    ];

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            width: 105,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(item['image']!, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.75), Colors.transparent, Colors.black.withOpacity(0.4)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          item['title']!,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['subtitle']!,
                              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 8),
                          ],
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
    );
  }
}

// بانر العروض السريعة Flash Offers المطابق تماماً للصورة
class _FlashOffersBanner extends StatelessWidget {
  const _FlashOffersBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF4A154B), Color(0xFF2D0C2E), Color(0xFF1A051B)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        boxShadow: [
          BoxShadow(color: Colors.purple.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8)),
        ],
        border: Border.all(color: Colors.pinkAccent.withOpacity(0.3), width: 1),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
              child: Image.network(
                'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?q=80&w=400',
                width: 150,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            left: 100,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, const Color(0xFF2D0C2E).withOpacity(0.9)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: const [
                    Icon(Icons.bolt_rounded, color: Colors.pinkAccent, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'FLASH OFFERS',
                      style: TextStyle(color: Colors.pinkAccent, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'عروض لفترة محدودة',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () {},
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('اكتشف الآن', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_back_ios, size: 8, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 12,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'حتى',
                  style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
                ),
                const Text(
                  '70%',
                  style: TextStyle(color: Colors.pinkAccent, fontSize: 22, fontWeight: FontWeight.w900, height: 1),
                ),
                const Text(
                  'خصم',
                  style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
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
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.72,
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

    return InkWell(
      onTap: () => context.push('/customer/product', extra: product),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardColor, 
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isLight ? Colors.black.withOpacity(0.04) : Colors.black.withOpacity(0.2), 
              blurRadius: 12, 
              offset: const Offset(0, 4)
            ),
          ],
          border: Border.all(
            color: isLight ? AppColors.lightBorder : AppColors.premiumDarkDivider.withOpacity(0.5), 
            width: 1
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: product.imageUrl.isNotEmpty 
                        ? Image.network(product.imageUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                        : Container(
                            width: double.infinity, 
                            color: isLight ? AppColors.lightSecondaryBackground : AppColors.premiumDarkSecondaryBackground, 
                            child: Center(child: Icon(Icons.image_rounded, color: textColor.withOpacity(0.2), size: 28))
                          ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.pinkAccent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '-30%',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.name, 
              style: TextStyle(
                fontWeight: FontWeight.w800, 
                fontSize: 12.5, 
                color: textColor
              ), 
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  '${product.price.round()} ${product.currency}', 
                  style: TextStyle(
                    color: primaryColor, 
                    fontWeight: FontWeight.w900, 
                    fontSize: 13
                  )
                ),
                const SizedBox(width: 4),
                Text(
                  '${(product.price * 1.3).round()} ${product.currency}',
                  style: TextStyle(
                    color: textColor.withOpacity(0.4),
                    fontSize: 10,
                    decoration: TextDecoration.lineThrough,
                    fontWeight: FontWeight.bold,
                  ),
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
        final displayShops = shops.isEmpty ? [
          ShopModel(id: 'zara', name: 'متجر زارا', imageUrl: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?q=80&w=400', rating: 4.8, deliveryTime: '15m', hasFreeDelivery: true),
          ShopModel(id: 'nike', name: 'متجر نايك', imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?q=80&w=400', rating: 4.9, deliveryTime: '20m', hasFreeDelivery: true),
          ShopModel(id: 'hm', name: 'متجر اتش اند ام', imageUrl: 'https://images.unsplash.com/photo-1445205170230-053b83016050?q=80&w=400', rating: 4.7, deliveryTime: '25m', hasFreeDelivery: false),
          ShopModel(id: 'shein', name: 'متجر شي ان', imageUrl: 'https://images.unsplash.com/photo-1483985988355-763728e1935b?q=80&w=400', rating: 4.6, deliveryTime: '30m', hasFreeDelivery: true),
        ] : shops;

        return SizedBox(
          height: 155,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: displayShops.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _FeaturedShopCard(shop: displayShops[index]),
          ),
        );
      },
      loading: () => SizedBox(height: 155, child: ListView(scrollDirection: Axis.horizontal, children: List.generate(2, (_) => const Padding(padding: EdgeInsets.only(right: 12), child: _Skeleton(width: 130, height: 155, radius: 20))))),
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isLight ? Colors.black.withOpacity(0.05) : Colors.black.withOpacity(0.2), 
              blurRadius: 12, 
              offset: const Offset(0, 5)
            )
          ],
          border: Border.all(color: isLight ? AppColors.lightBorder : AppColors.premiumDarkDivider.withOpacity(0.5), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: shop.imageUrl.isNotEmpty 
                    ? Image.network(shop.imageUrl, width: double.infinity, fit: BoxFit.cover)
                    : Container(color: isLight ? AppColors.lightSecondaryBackground : AppColors.premiumDarkSecondaryBackground, child: const Center(child: Icon(Icons.storefront_rounded, size: 30))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Column(
                children: [
                  Text(
                    shop.name, 
                    style: TextStyle(
                      fontWeight: FontWeight.w900, 
                      fontSize: 13, 
                      color: textColor
                    ), 
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'متجر معتمد',
                    style: TextStyle(color: theme.colorScheme.primary, fontSize: 10, fontWeight: FontWeight.w700),
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
      loading: () => SizedBox(height: 220, child: ListView(scrollDirection: Axis.horizontal, children: List.generate(2, (_) => const Padding(padding: EdgeInsets.only(right: 12), child: _Skeleton(width: 145, height: 220, radius: 20))))),
      error: (e, s) => const SizedBox.shrink(),
    );
  }
}
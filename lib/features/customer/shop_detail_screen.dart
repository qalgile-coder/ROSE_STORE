import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers.dart';
import '../../core/localization.dart';
import '../../theme/app_colors.dart';
import '../../models/product_model.dart';
import '../../models/shop_model.dart';
import '../../models/review_model.dart';
import 'package:intl/intl.dart';

class ShopDetailScreen extends ConsumerStatefulWidget {
  final String shopId;
  const ShopDetailScreen({super.key, required this.shopId});

  @override
  ConsumerState<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends ConsumerState<ShopDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopAsync = ref.watch(shopDetailProvider(widget.shopId));
    final productsAsync = ref.watch(shopProductsByIdProvider(widget.shopId));
    final cart = ref.watch(cartProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return shopAsync.when(
      data: (shop) {
        if (shop == null) return const Scaffold(body: Center(child: Text('Shop not found')));

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildSliverAppBar(context, shop),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  shop.name, 
                                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: colorScheme.onSurface, letterSpacing: -1)
                                ),
                                const SizedBox(height: 6),
                                Text(shop.category.toUpperCase(), style: TextStyle(color: colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                              ],
                            ),
                          ),
                          _buildActionIcons(),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildShopStats(shop),
                      const SizedBox(height: 24),
                      Text(
                        shop.description, 
                        style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), height: 1.6, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 24),
                      _ContactBar(phone: shop.phone, address: shop.address),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  theme.scaffoldBackgroundColor,
                  TabBar(
                    controller: _tabController,
                    labelColor: colorScheme.primary,
                    unselectedLabelColor: colorScheme.onSurface.withOpacity(0.4),
                    indicatorColor: colorScheme.primary,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    tabs: const [
                      Tab(text: 'PRODUCTS'),
                      Tab(text: 'REVIEWS'),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildProductsTab(productsAsync, shop),
                _buildReviewsTab(shop.id),
              ],
            ),
          ),
          bottomNavigationBar: cart.itemCount > 0 ? _buildCartSummary(context, cart) : null,
        );
      },
      loading: () => Scaffold(backgroundColor: theme.scaffoldBackgroundColor, body: Center(child: CircularProgressIndicator(color: colorScheme.primary))),
      error: (e, s) => Scaffold(backgroundColor: theme.scaffoldBackgroundColor, body: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildActionIcons() {
    return Row(
      children: [
        _CircleIconButton(icon: Icons.share_rounded, onTap: () {}),
        const SizedBox(width: 12),
        _CircleIconButton(icon: Icons.favorite_rounded, color: AppColors.error, onTap: () {}),
      ],
    );
  }

  Widget _buildShopStats(ShopModel shop) {
    return Row(
      children: [
        _InfoChip(icon: Icons.star_rounded, label: '${shop.rating}', color: AppColors.warning),
        const SizedBox(width: 12),
        _InfoChip(icon: Icons.timer_rounded, label: shop.deliveryTime, color: AppColors.info),
        const SizedBox(width: 12),
        _InfoChip(icon: Icons.delivery_dining_rounded, label: shop.hasFreeDelivery ? 'Free' : 'Paid', color: AppColors.success),
      ],
    );
  }

  Widget _buildProductsTab(AsyncValue<List<ProductModel>> productsAsync, ShopModel shop) {
    final colorScheme = Theme.of(context).colorScheme;
    return productsAsync.when(
      data: (products) {
        final filtered = products.where((p) => p.name.toLowerCase().contains(_searchQuery)).toList();
        
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search inside store...',
                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: colorScheme.primary),
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty 
                ? Center(child: Text('No products available.', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4))))
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) => _ProductTile(product: filtered[index], shop: shop),
                  ),
            ),
          ],
        );
      },
      loading: () => Center(child: CircularProgressIndicator(color: colorScheme.primary)),
      error: (e, s) => const Center(child: Text('Error loading products')),
    );
  }

  Widget _buildReviewsTab(String shopId) {
    final colorScheme = Theme.of(context).colorScheme;
    final reviewsAsync = ref.watch(shopReviewsProviderFromService(shopId));

    return reviewsAsync.when(
      data: (reviews) {
        if (reviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.rate_review_rounded, size: 64, color: colorScheme.onSurface.withValues(alpha: 0.05)),
                const SizedBox(height: 16),
                Text('No ratings yet.', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: reviews.length,
          separatorBuilder: (context, index) => const SizedBox(height: 20),
          itemBuilder: (context, index) => _ShopReviewTile(review: reviews[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading reviews')),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, ShopModel shop) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: isLight ? Colors.white.withOpacity(0.8) : AppColors.surface.withOpacity(0.8),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: colorScheme.onSurface),
            onPressed: () => context.canPop() ? context.pop() : context.go('/customer'),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: shop.imageUrl.isNotEmpty 
            ? Image.network(shop.imageUrl, fit: BoxFit.cover)
            : Container(color: colorScheme.surface, child: Icon(Icons.storefront, size: 80, color: colorScheme.onSurface.withOpacity(0.05))),
      ),
    );
  }

  Widget _buildCartSummary(BuildContext context, dynamic cart) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : AppColors.bottomNav,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: isLight ? Colors.black.withOpacity(0.08) : Colors.black.withOpacity(0.2), 
            blurRadius: 30
          )
        ],
        border: isLight ? Border.all(color: colorScheme.outline.withOpacity(0.1)) : null,
      ),
      child: ElevatedButton(
        onPressed: () => context.push('/customer/cart'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${cart.totalQuantity} ITEMS', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  Text('Rs ${cart.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white)),
                ],
              ),
              Row(
                children: const [
                  Text('VIEW CART', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          shape: BoxShape.circle,
          boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] : null,
          border: isLight ? Border.all(color: colorScheme.outline.withOpacity(0.1)) : null,
        ),
        child: Icon(icon, color: color ?? colorScheme.onSurface, size: 20),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this.backgroundColor, this._tabBar);
  final Color backgroundColor;
  final TabBar _tabBar;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: _tabBar,
    );
  }
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ContactBar extends StatelessWidget {
  final String phone;
  final String address;
  const _ContactBar({required this.phone, required this.address});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface, 
        borderRadius: BorderRadius.circular(22),
        boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20)] : null,
        border: isLight ? Border.all(color: colorScheme.outline.withOpacity(0.05)) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Location', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: colorScheme.onSurface)),
                const SizedBox(height: 2),
                Text(address, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => launchUrl(Uri.parse('tel:$phone')),
            icon: Icon(Icons.call_rounded, color: colorScheme.primary, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: isLight ? colorScheme.primary.withOpacity(0.08) : AppColors.background, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopReviewTile extends StatelessWidget {
  final ReviewModel review;
  const _ShopReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final secondaryTextColor = colorScheme.onSurface.withValues(alpha: 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(review.customerName, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: colorScheme.onSurface)),
            Row(
              children: List.generate(5, (index) => Icon(
                Icons.star_rounded, 
                size: 16, 
                color: index < review.rating ? Colors.orange : colorScheme.onSurface.withValues(alpha: 0.1)
              )),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('MMM dd, yyyy').format(review.createdAt),
          style: TextStyle(color: secondaryTextColor.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          review.review,
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.8), fontSize: 14, height: 1.5, fontWeight: FontWeight.w500),
        ),
        if (review.reply != null && review.reply!.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.reply_rounded, color: colorScheme.primary, size: 16),
                    const SizedBox(width: 8),
                    Text('RESPONSE FROM VENDOR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: colorScheme.primary, letterSpacing: 1)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  review.reply!,
                  style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13, height: 1.4, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ProductTile extends ConsumerWidget {
  final ProductModel product;
  final ShopModel shop;
  const _ProductTile({required this.product, required this.shop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return InkWell(
      onTap: () => context.push('/customer/product', extra: product),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)] : null,
          border: isLight ? Border.all(color: colorScheme.outline.withOpacity(0.05)) : null,
        ),
        child: Row(
          children: [
            Hero(
              tag: 'product_${product.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: product.imageUrl.isNotEmpty 
                  ? Image.network(product.imageUrl, width: 90, height: 90, fit: BoxFit.cover)
                  : Container(width: 90, height: 90, color: colorScheme.onSurface.withOpacity(0.05), child: Icon(Icons.image, color: colorScheme.onSurface.withOpacity(0.1))),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name, 
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: colorScheme.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    maxLines: 1,
                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rs ${product.price.toStringAsFixed(0)}', 
                        style: TextStyle(fontWeight: FontWeight.w800, color: colorScheme.primary, fontSize: 18)
                      ),
                      InkWell(
                        onTap: () {
                          ref.read(cartProvider.notifier).addItem(
                            product, 
                            shopName: shop.name, 
                            shopImageUrl: shop.imageUrl
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product.name} added to cart'),
                              backgroundColor: colorScheme.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.add_rounded, color: isLight ? Colors.white : AppColors.background, size: 20),
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

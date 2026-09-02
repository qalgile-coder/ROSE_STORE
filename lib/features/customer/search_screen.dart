import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/utils.dart';
import '../../models/product_model.dart';
import '../../models/shop_model.dart';
import '../../theme/app_colors.dart';

class CustomerSearchScreen extends ConsumerStatefulWidget {
  const CustomerSearchScreen({super.key});

  @override
  ConsumerState<CustomerSearchScreen> createState() => _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends ConsumerState<CustomerSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  // Filter States
  String? _selectedCategory;
  RangeValues _priceRange = const RangeValues(0, 5000);
  double _minRating = 0;
  double _maxDistance = 10.0; 
  bool _freeDelivery = false;
  bool _onlyOffers = false;
  bool _onlyOpen = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterBottomSheet(
        initialCategory: _selectedCategory,
        initialPriceRange: _priceRange,
        initialRating: _minRating,
        initialMaxDistance: _maxDistance,
        initialFreeDelivery: _freeDelivery,
        initialOnlyOffers: _onlyOffers,
        initialOnlyOpen: _onlyOpen,
        onApply: (cat, price, rating, dist, free, offers, open) {
          setState(() {
            _selectedCategory = cat;
            _priceRange = price;
            _minRating = rating;
            _maxDistance = dist;
            _freeDelivery = free;
            _onlyOffers = offers;
            _onlyOpen = open;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(searchProductsProvider(_query));
    final shopsAsync = ref.watch(searchShopsProvider(_query));
    final userAddress = ref.watch(defaultAddressProvider);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor.withOpacity(0.8),
        elevation: 0,
        toolbarHeight: 90,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: colorScheme.onBackground),
              onPressed: () => context.canPop() ? context.pop() : context.go('/customer'),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surface,
                fixedSize: const Size(45, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                side: isLight ? BorderSide(color: colorScheme.outline.withOpacity(0.1)) : null,
              ),
            ),
          ),
        ),
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: isLight ? colorScheme.outline.withOpacity(0.1) : Colors.white.withOpacity(0.06)),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
            textAlignVertical: TextAlignVertical.center,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Search products or shops...',
              hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.3), fontSize: 13, fontWeight: FontWeight.w500),
              prefixIcon: Icon(Icons.search_rounded, size: 20, color: colorScheme.primary.withOpacity(0.8)),
              suffixIcon: _query.isNotEmpty ? IconButton(
                icon: Icon(Icons.close_rounded, size: 16, color: colorScheme.onSurface.withOpacity(0.4)), 
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                }
              ) : null,
              border: InputBorder.none,
              isCollapsed: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: _openFilters,
              icon: Icon(
                Icons.tune_rounded,
                size: 20,
                color: (_selectedCategory != null || _minRating > 0 || _freeDelivery || _onlyOffers || _onlyOpen) ? colorScheme.primary : colorScheme.onBackground,
              ),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surface,
                fixedSize: const Size(45, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                side: isLight ? BorderSide(color: colorScheme.outline.withOpacity(0.1)) : null,
              ),
            ),
          ),
        ],
      ),
      body: _query.isEmpty 
          ? const _SearchPlaceholder() 
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shops Result
                  shopsAsync.when(
                    data: (shops) {
                      final filteredShops = shops.where((s) {
                        final matchesCat = _selectedCategory == null || s.category == _selectedCategory;
                        final matchesRating = s.rating >= _minRating;
                        final matchesFree = !_freeDelivery || s.hasFreeDelivery;
                        final matchesOpen = !_onlyOpen || s.isOpen;
                        final distance = MapUtils.calculateDistance(userAddress?.location, s.location);
                        final matchesDist = distance <= _maxDistance;
                        return matchesCat && matchesRating && matchesFree && matchesOpen && matchesDist;
                      }).toList();

                      if (filteredShops.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _ResultHeader(title: 'Top Shops'),
                          const SizedBox(height: 16),
                          ...filteredShops.map((shop) => _ShopSearchCard(shop: shop)),
                          const SizedBox(height: 32),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (e, s) => const SizedBox.shrink(),
                  ),

                  // Products Result
                  productsAsync.when(
                    data: (products) {
                      var filtered = products.where((p) {
                        final matchesCat = _selectedCategory == null || p.category == _selectedCategory;
                        final matchesPrice = p.price >= _priceRange.start && p.price <= _priceRange.end;
                        final matchesOffers = !_onlyOffers || p.discount > 0;
                        return matchesCat && matchesPrice && matchesOffers;
                      }).toList();

                      if (filtered.isEmpty && !shopsAsync.hasValue) {
                        return const _NoResultsFound();
                      }
                      if (filtered.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _ResultHeader(title: 'Premium Products'),
                          const SizedBox(height: 16),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) => _ProductSearchCard(product: filtered[index]),
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )),
                    error: (e, s) => const Center(child: Text('Error loading results', style: TextStyle(color: AppColors.error))),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ResultHeader extends StatelessWidget {
  final String title;
  const _ResultHeader({required this.title});
  @override
  Widget build(BuildContext context) => Text(
    title.toUpperCase(), 
    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 1.5)
  );
}

class _SearchPlaceholder extends StatelessWidget {
  const _SearchPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return Stack(
      children: [
        // Background Glow
        Positioned(
          top: MediaQuery.of(context).size.height * 0.1,
          left: MediaQuery.of(context).size.width * 0.2,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [colorScheme.primary.withOpacity(isLight ? 0.12 : 0.08), Colors.transparent],
              ),
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withOpacity(isLight ? 1.0 : 0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: isLight ? Colors.black.withOpacity(0.05) : Colors.black.withOpacity(0.2), 
                        blurRadius: 40, 
                        spreadRadius: -10
                      ),
                    ],
                  ),
                  child: Icon(Icons.search_rounded, size: 72, color: colorScheme.primary.withOpacity(0.4)),
                ),
                const SizedBox(height: 40),
                Text(
                  'What are you looking for?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.w900, 
                    color: colorScheme.onBackground, 
                    letterSpacing: -0.5
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Explore premium shops and products instantly through our smart search.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 15, 
                    fontWeight: FontWeight.w500,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NoResultsFound extends StatelessWidget {
  const _NoResultsFound();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.search_off_rounded, size: 64, color: Colors.white10),
        const SizedBox(height: 20),
        const Text('No matches found.', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 8),
        const Text('Try adjusting your filters or keywords.', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
      ],
    ),
  );
}

class _ShopSearchCard extends StatelessWidget {
  final ShopModel shop;
  const _ShopSearchCard({required this.shop});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return InkWell(
      onTap: () => context.push('/customer/shop/${shop.id}'),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)] : null,
          border: isLight ? Border.all(color: colorScheme.outline.withOpacity(0.1)) : Border.all(color: colorScheme.outline.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: shop.imageUrl.isNotEmpty 
                ? Image.network(shop.imageUrl, width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(width: 70, height: 70, color: colorScheme.surface, child: Icon(Icons.storefront, color: colorScheme.onSurface.withOpacity(0.1))))
                : Container(width: 70, height: 70, color: colorScheme.surface, child: Icon(Icons.storefront, color: colorScheme.onSurface.withOpacity(0.1))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shop.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(shop.category, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Container(width: 3, height: 3, decoration: BoxDecoration(color: colorScheme.onSurface.withOpacity(0.2), shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      const Icon(Icons.star_rounded, color: AppColors.warning, size: 14),
                      Text(' ${shop.rating}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductSearchCard extends StatelessWidget {
  final ProductModel product;
  const _ProductSearchCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return InkWell(
      onTap: () => context.push('/customer/product', extra: product),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20)] : null,
          border: isLight ? Border.all(color: colorScheme.outline.withOpacity(0.05)) : null,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: product.imageUrl.isNotEmpty 
                ? Image.network(product.imageUrl, width: 85, height: 85, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 85, height: 85, color: colorScheme.surface, child: Icon(Icons.image, color: colorScheme.onSurface.withOpacity(0.1))))
                : Container(width: 85, height: 85, color: colorScheme.surface, child: Icon(Icons.image, color: colorScheme.onSurface.withOpacity(0.1))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name, 
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: colorScheme.onSurface, letterSpacing: -0.2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${product.brand} • ${product.category}', 
                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.w600)
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Rs ${product.price.toStringAsFixed(0)}', 
                        style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.primary, fontSize: 17)
                      ),
                      if (product.discount > 0) ...[
                        const SizedBox(width: 10),
                        Text(
                          'Rs ${product.price + product.discount}', 
                          style: TextStyle(color: colorScheme.onSurface.withOpacity(0.2), fontSize: 12, decoration: TextDecoration.lineThrough, fontWeight: FontWeight.w600)
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colorScheme.onSurface.withOpacity(0.1)),
          ],
        ),
      ),
    );
  }
}

class _FilterBottomSheet extends ConsumerStatefulWidget {
  final String? initialCategory;
  final RangeValues initialPriceRange;
  final double initialRating;
  final double initialMaxDistance;
  final bool initialFreeDelivery;
  final bool initialOnlyOffers;
  final bool initialOnlyOpen;
  final Function(String?, RangeValues, double, double, bool, bool, bool) onApply;

  const _FilterBottomSheet({this.initialCategory, required this.initialPriceRange, required this.initialRating, required this.initialMaxDistance, required this.initialFreeDelivery, required this.initialOnlyOffers, required this.initialOnlyOpen, required this.onApply});
  @override
  ConsumerState<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<_FilterBottomSheet> {
  String? _selectedCategory;
  RangeValues _priceRange = const RangeValues(0, 5000);
  double _minRating = 0;
  double _maxDistance = 10.0;
  bool _freeDelivery = false;
  bool _onlyOffers = false;
  bool _onlyOpen = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _priceRange = widget.initialPriceRange;
    _minRating = widget.initialRating;
    _maxDistance = widget.initialMaxDistance;
    _freeDelivery = widget.initialFreeDelivery;
    _onlyOffers = widget.initialOnlyOffers;
    _onlyOpen = widget.initialOnlyOpen;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.dialog, 
        borderRadius: BorderRadius.vertical(top: Radius.circular(36))
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border.withOpacity(0.5), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          const Text('Refine Search', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 32),
          const Text('Price Range', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
          RangeSlider(
            values: _priceRange, 
            min: 0, 
            max: 5000, 
            divisions: 25, 
            activeColor: AppColors.primary, 
            inactiveColor: AppColors.primary.withOpacity(0.1), 
            labels: RangeLabels('Rs ${_priceRange.start.round()}', 'Rs ${_priceRange.end.round()}'), 
            onChanged: (v) => setState(() => _priceRange = v)
          ),
          const SizedBox(height: 24),
          const Text('Quick Selection', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
          const SizedBox(height: 12),
          Wrap(spacing: 10, children: [
            _QuickChip(label: 'Free Delivery', selected: _freeDelivery, onToggle: (v) => setState(() => _freeDelivery = v)),
            _QuickChip(label: 'On Offer', selected: _onlyOffers, onToggle: (v) => setState(() => _onlyOffers = v)),
            _QuickChip(label: 'Open Now', selected: _onlyOpen, onToggle: (v) => setState(() => _onlyOpen = v)),
          ]),
          const SizedBox(height: 24),
          const Text('Minimum Rating', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(4, (i) {
                final r = (i + 2).toDouble();
                final isSel = _minRating == r;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () => setState(() => _minRating = isSel ? 0 : r),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.primary : AppColors.surface, 
                        borderRadius: BorderRadius.circular(12), 
                        border: Border.all(color: isSel ? AppColors.primary : AppColors.border)
                      ),
                      child: Text('$r+ ★', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: isSel ? AppColors.background : Colors.white))
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () { 
              widget.onApply(_selectedCategory, _priceRange, _minRating, _maxDistance, _freeDelivery, _onlyOffers, _onlyOpen); 
              Navigator.pop(context); 
            }, 
            child: const Text('Apply Filters')
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Function(bool) onToggle;
  const _QuickChip({required this.label, required this.selected, required this.onToggle});
  @override
  Widget build(BuildContext context) => FilterChip(
    label: Text(label), 
    selected: selected, 
    onSelected: onToggle, 
    selectedColor: AppColors.primary.withOpacity(0.1), 
    checkmarkColor: AppColors.primary, 
    labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: selected ? AppColors.primary : AppColors.textSecondary), 
    backgroundColor: AppColors.surface, 
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: selected ? AppColors.primary : AppColors.border))
  );
}

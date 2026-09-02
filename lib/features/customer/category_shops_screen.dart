import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../models/shop_model.dart';
import '../../theme/app_colors.dart';

class CategoryShopsScreen extends ConsumerStatefulWidget {
  final String category;
  const CategoryShopsScreen({super.key, required this.category});

  @override
  ConsumerState<CategoryShopsScreen> createState() => _CategoryShopsScreenState();
}

class _CategoryShopsScreenState extends ConsumerState<CategoryShopsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final shopsAsync = ref.watch(categoryShopsProvider(widget.category));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('${widget.category} Stores', style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.onBackground)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: colorScheme.onBackground),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outline.withOpacity(isLight ? 1.0 : 0.2)),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Search for ${widget.category.toLowerCase()} stores...',
                  hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.4), fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: colorScheme.primary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
        ),
      ),
      body: shopsAsync.when(
        data: (shops) {
          final filtered = shops.where((s) => s.name.toLowerCase().contains(_searchQuery)).toList();
          
          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.storefront_rounded, size: 64, color: colorScheme.onSurface.withOpacity(0.1)),
                  const SizedBox(height: 16),
                  Text('No stores found in ${widget.category}', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4), fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: filtered.length,
            physics: const BouncingScrollPhysics(),
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            itemBuilder: (context, index) => _ShopListTile(
              shop: filtered[index],
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

class _ShopListTile extends StatelessWidget {
  final ShopModel shop;
  final bool isLight;
  final ColorScheme colorScheme;

  const _ShopListTile({required this.shop, required this.isLight, required this.colorScheme});

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
              color: isLight ? Colors.black.withOpacity(0.05) : Colors.black.withOpacity(0.2), 
              blurRadius: 20, 
              offset: const Offset(0, 8)
            ),
          ],
          border: isLight ? Border.all(color: colorScheme.outline.withOpacity(0.1)) : Border.all(color: colorScheme.outline.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'shop_banner_${shop.id}',
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: isLight ? AppColors.lightSecondaryBackground : AppColors.premiumDarkSecondaryBackground,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      image: shop.imageUrl.isNotEmpty 
                          ? DecorationImage(image: NetworkImage(shop.imageUrl), fit: BoxFit.cover)
                          : null,
                    ),
                    child: shop.imageUrl.isEmpty 
                        ? Center(child: Icon(Icons.storefront, size: 48, color: colorScheme.onSurface.withOpacity(0.1)))
                        : null,
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: AppColors.warning, size: 16),
                            const SizedBox(width: 4),
                            Text(shop.rating.toString(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop.name, 
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: colorScheme.onSurface, letterSpacing: -0.2)
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${shop.deliveryTime} • ${shop.address}', 
                          style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w500), 
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_forward_rounded, size: 18, color: colorScheme.primary),
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

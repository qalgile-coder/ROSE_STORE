import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../models/product_model.dart';
import '../../theme/app_colors.dart';

class TrendingProductsScreen extends ConsumerStatefulWidget {
  const TrendingProductsScreen({super.key});

  @override
  ConsumerState<TrendingProductsScreen> createState() => _TrendingProductsScreenState();
}

class _TrendingProductsScreenState extends ConsumerState<TrendingProductsScreen> {
  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(trendingProductsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Trending Now', style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.onBackground)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: colorScheme.onBackground),
          onPressed: () => context.pop(),
        ),
      ),
      body: productsAsync.when(
        data: (products) {
          if (products.isEmpty) return _EmptyState(colorScheme: colorScheme);

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 0.72,
            ),
            itemCount: products.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) => _TrendingProductCard(
              product: products[index],
              colorScheme: colorScheme,
              isLight: isLight,
            ),
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: colorScheme.primary)),
        error: (e, s) => Center(child: Text('Error: $e', style: TextStyle(color: colorScheme.error))),
      ),
    );
  }
}

class _TrendingProductCard extends StatelessWidget {
  final ProductModel product;
  final ColorScheme colorScheme;
  final bool isLight;

  const _TrendingProductCard({required this.product, required this.colorScheme, required this.isLight});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/customer/product', extra: product),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)] : null,
          border: Border.all(color: colorScheme.outline.withOpacity(isLight ? 0.1 : 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Hero(
                    tag: 'product_trending_${product.id}',
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                        image: DecorationImage(image: NetworkImage(product.imageUrl), fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.favorite_border_rounded, size: 16, color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name, 
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: colorScheme.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category, 
                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rs ${product.price.round()}', 
                        style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
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

class _EmptyState extends StatelessWidget {
  final ColorScheme colorScheme;
  const _EmptyState({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bolt_rounded, size: 64, color: colorScheme.onSurface.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text('No trending items yet', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

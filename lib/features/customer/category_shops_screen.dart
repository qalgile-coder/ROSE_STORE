import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../models/product_model.dart';
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
    // استخدام المزود الاحترافي الجديد لجلب منتجات القسم مباشرة بناءً على المفتاح المطابق لقاعدة البيانات
    final productsAsync = ref.watch(categoryProductsProvider(widget.category));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('${widget.category} Products', style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.onBackground)),
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
                  hintText: 'Search in ${widget.category.toLowerCase()}...',
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
      body: productsAsync.when(
        data: (products) {
          final filtered = products.where((p) => p.name.toLowerCase().contains(_searchQuery)).toList();
          
          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: colorScheme.onSurface.withOpacity(0.1)),
                  const SizedBox(height: 16),
                  Text('No products found in ${widget.category}', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4), fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: filtered.length,
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemBuilder: (context, index) => _ProductCard(
              product: filtered[index],
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

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final bool isLight;
  final ColorScheme colorScheme;

  const _ProductCard({required this.product, required this.isLight, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/customer/product/${product.id}'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isLight ? Colors.black.withOpacity(0.04) : Colors.black.withOpacity(0.2), 
              blurRadius: 15, 
              offset: const Offset(0, 6)
            ),
          ],
          border: isLight ? Border.all(color: colorScheme.outline.withOpacity(0.1)) : Border.all(color: colorScheme.outline.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Container(
                  width: double.infinity,
                  color: isLight ? AppColors.lightSecondaryBackground : AppColors.premiumDarkSecondaryBackground,
                  child: product.imageUrl.isNotEmpty 
                      ? Image.network(product.imageUrl, fit: BoxFit.cover)
                      : Icon(Icons.shopping_bag, size: 36, color: colorScheme.onSurface.withOpacity(0.1)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
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
                    '${product.price} ${product.currency}', 
                    style: TextStyle(color: colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w900),
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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../models/product_model.dart';
import '../../theme/app_colors.dart';
import './widgets/vendor_bottom_nav.dart';

class ProductManagementScreen extends ConsumerStatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  ConsumerState<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends ConsumerState<ProductManagementScreen> with SingleTickerProviderStateMixin {
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final productsAsync = ref.watch(shopProductsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Inventory Management', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: colorScheme.onSurface),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/vendor');
            }
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outline.withOpacity(isLight ? 0.5 : 0.05)),
                    boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)] : null,
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                    style: TextStyle(fontSize: 14, color: colorScheme.onSurface, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.3), fontSize: 13),
                      prefixIcon: Icon(Icons.search_rounded, size: 20, color: colorScheme.primary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TabBar(
                controller: _tabController,
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurface.withOpacity(0.4),
                indicatorColor: colorScheme.primary,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: const [
                  Tab(text: 'ALL PRODUCTS'),
                  Tab(text: 'CATEGORIES'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          // All Products Tab
          productsAsync.when(
            data: (products) {
              final filtered = products.where((p) => p.name.toLowerCase().contains(_searchQuery)).toList();
              
              if (filtered.isEmpty) {
                return _EmptyState(icon: Icons.inventory_2_rounded, message: 'No products found', colorScheme: colorScheme);
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                itemCount: filtered.length,
                physics: const BouncingScrollPhysics(),
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) => _ProductManagementTile(product: filtered[index]),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          ),
          // Categories Tab
          productsAsync.when(
            data: (products) {
              final categories = products.map((p) => p.category).toSet().toList();
              if (categories.isEmpty) {
                return _EmptyState(icon: Icons.category_rounded, message: 'No categories found', colorScheme: colorScheme);
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                itemCount: categories.length,
                physics: const BouncingScrollPhysics(),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final count = products.where((p) => p.category == cat).length;
                  return _CategoryTile(name: cat, count: count, colorScheme: colorScheme, isLight: isLight);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/vendor/add-product'),
        backgroundColor: colorScheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('ADD PRODUCT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      ),
      bottomNavigationBar: const VendorBottomNav(currentIndex: 2),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final ColorScheme colorScheme;
  const _EmptyState({required this.icon, required this.message, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: colorScheme.onSurface.withOpacity(0.05)),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String name;
  final int count;
  final ColorScheme colorScheme;
  final bool isLight;
  const _CategoryTile({required this.name, required this.count, required this.colorScheme, required this.isLight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withOpacity(isLight ? 0.5 : 0.05)),
        boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)] : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.category_rounded, color: colorScheme.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isLight ? AppColors.lightSecondaryBackground : AppColors.premiumDarkSecondaryBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('$count Items', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: colorScheme.onSurface.withOpacity(0.4))),
          ),
        ],
      ),
    );
  }
}

class _ProductManagementTile extends ConsumerWidget {
  final ProductModel product;
  const _ProductManagementTile({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outline.withOpacity(isLight ? 0.5 : 0.05)),
        boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)] : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Hero(
                tag: 'prod_${product.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    product.imageUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(width: 70, height: 70, color: colorScheme.onSurface.withOpacity(0.05), child: Icon(Icons.image, color: colorScheme.onSurface.withOpacity(0.1))),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _StockBadge(label: 'STOCK: ${product.stock}', color: product.stock < 10 ? AppColors.error : AppColors.success),
                        const SizedBox(width: 8),
                        _StockBadge(label: 'SOLD: ${product.soldQuantity}', color: AppColors.info),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Rs ${product.price.round()}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: colorScheme.primary)),
                  const SizedBox(height: 4),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch.adaptive(
                      value: product.isAvailable,
                      activeColor: AppColors.success,
                      onChanged: (v) {
                        ref.read(vendorServiceProvider).updateProduct(product.id, {'isAvailable': v});
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: colorScheme.outline.withOpacity(0.1)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ActionButton(
                icon: Icons.edit_rounded,
                label: 'Edit',
                onTap: () => _showEditProductDialog(context, ref, colorScheme),
                color: colorScheme.onSurface,
              ),
              _ActionButton(
                icon: Icons.sell_rounded,
                label: 'Price',
                onTap: () => _showUpdatePriceDialog(context, ref, colorScheme),
                color: colorScheme.onSurface,
              ),
              _ActionButton(
                icon: Icons.inventory_rounded,
                label: 'Stock',
                onTap: () => _showUpdateStockDialog(context, ref, colorScheme),
                color: colorScheme.onSurface,
              ),
              _ActionButton(
                icon: Icons.delete_sweep_rounded,
                label: 'Delete',
                color: AppColors.error,
                onTap: () => _showDeleteDialog(context, ref, colorScheme),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditProductDialog(BuildContext context, WidgetRef ref, ColorScheme colorScheme) {
    final nameController = TextEditingController(text: product.name);
    final descController = TextEditingController(text: product.description);
    final categoryController = TextEditingController(text: product.category);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Edit Product Info', style: TextStyle(fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Product Name', prefixIcon: Icon(Icons.shopping_bag_rounded)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description_rounded)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_rounded)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              ref.read(vendorServiceProvider).updateProduct(product.id, {
                'name': nameController.text.trim(),
                'description': descController.text.trim(),
                'category': categoryController.text.trim(),
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(100, 48)),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _showUpdatePriceDialog(BuildContext context, WidgetRef ref, ColorScheme colorScheme) {
    final controller = TextEditingController(text: product.price.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Price', style: TextStyle(fontWeight: FontWeight.w900)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(prefixText: 'Rs ', labelText: 'New Price'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              final newPrice = double.tryParse(controller.text);
              if (newPrice != null) {
                ref.read(vendorServiceProvider).updateProduct(product.id, {'price': newPrice});
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(100, 48)),
            child: const Text('UPDATE'),
          ),
        ],
      ),
    );
  }

  void _showUpdateStockDialog(BuildContext context, WidgetRef ref, ColorScheme colorScheme) {
    final controller = TextEditingController(text: product.stock.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Stock', style: TextStyle(fontWeight: FontWeight.w900)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: ' Units', labelText: 'Inventory Count'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              final newStock = int.tryParse(controller.text);
              if (newStock != null) {
                ref.read(vendorServiceProvider).updateProduct(product.id, {'stock': newStock});
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(100, 48)),
            child: const Text('UPDATE'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Are you sure you want to remove "${product.name}" from your store?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              ref.read(vendorServiceProvider).deleteProduct(product.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, minimumSize: const Size(100, 48)),
            child: const Text('DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StockBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color?.withOpacity(0.8) ?? Colors.black),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color?.withOpacity(0.8) ?? Colors.black)),
          ],
        ),
      ),
    );
  }
}

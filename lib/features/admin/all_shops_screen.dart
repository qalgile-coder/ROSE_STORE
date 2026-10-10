import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../models/shop_model.dart';

class AllShopsScreen extends ConsumerStatefulWidget {
  const AllShopsScreen({super.key});

  @override
  ConsumerState<AllShopsScreen> createState() => _AllShopsScreenState();
}

class _AllShopsScreenState extends ConsumerState<AllShopsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final shopsAsync = ref.watch(allShopsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(130),
        child: Column(
          children: [
            AppBar(
              title: const Text('All Shops', style: TextStyle(fontWeight: FontWeight.w900)),
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: colorScheme.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search shops by name or vendor...',
                    hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3)),
                    border: InputBorder.none,
                    icon: Icon(Icons.search, size: 20, color: colorScheme.primary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: shopsAsync.when(
        data: (shops) {
          final filtered = shops.where((s) => 
            s.name.toLowerCase().contains(_searchQuery) || 
            s.vendorName.toLowerCase().contains(_searchQuery)
          ).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.storefront_rounded, size: 64, color: colorScheme.onSurface.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),
                  Text('No shops found.', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _ShopListTile(shop: filtered[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/add-vendor'), 
        backgroundColor: colorScheme.primary,
        icon: const Icon(Icons.add_business_rounded, color: Colors.white),
        label: const Text('CREATE SHOP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
    );
  }
}

class _ShopListTile extends ConsumerWidget {
  final ShopModel shop;
  const _ShopListTile({required this.shop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isDisabled = shop.status == 'disabled';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: shop.imageUrl.isNotEmpty 
                  ? Image.network(shop.imageUrl, width: 64, height: 64, fit: BoxFit.cover)
                  : Container(
                      width: 64, height: 64, 
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      child: Icon(Icons.storefront_rounded, color: colorScheme.primary),
                    ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vendor: ${shop.vendorName}',
                      style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Category: ${shop.category}',
                      style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isDisabled ? const Color(0xFFEF4444) : const Color(0xFF10B981)).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      shop.status.toUpperCase(),
                      style: TextStyle(
                        color: isDisabled ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                      Text(' ${shop.rating}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: colorScheme.onSurface)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ActionButton(
                icon: Icons.visibility_outlined,
                label: 'View',
                onTap: () => context.push('/customer/shop/${shop.id}'),
              ),
              _ActionButton(
                icon: Icons.edit_outlined,
                label: 'Edit',
                onTap: () {},
              ),
              _ActionButton(
                icon: isDisabled ? Icons.play_circle_outline_rounded : Icons.block_rounded,
                label: isDisabled ? 'Enable' : 'Disable',
                color: isDisabled ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                onTap: () {
                  ref.read(adminServiceProvider).updateShopStatus(
                    shop.id, 
                    isDisabled ? 'active' : 'disabled'
                  );
                },
              ),
              _ActionButton(
                icon: Icons.delete_outline_rounded,
                label: 'Delete',
                color: const Color(0xFFEF4444),
                onTap: () => _showDeleteDialog(context, ref, shop),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, ShopModel shop) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shop?'),
        content: Text('Are you sure you want to delete "${shop.name}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(adminServiceProvider).deleteShop(shop.id);
              context.pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 20, color: color ?? colorScheme.onSurface.withValues(alpha: 0.6)),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color ?? colorScheme.onSurface.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}

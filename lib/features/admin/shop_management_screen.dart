import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../models/offer_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_colors.dart';

class _PromoBannersSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(allOffersProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: colorScheme.onSurface.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Promo Banners', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                IconButton(
                  onPressed: () => _showAddOfferDialog(context, ref),
                  icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF10B981), size: 32),
                ),
              ],
            ),
          ),
          Expanded(
            child: offersAsync.when(
              data: (offers) {
                if (offers.isEmpty) return const Center(child: Text('No banners active.'));
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: offers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final offer = offers[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(offer.imageUrl, width: 100, height: 60, fit: BoxFit.cover, 
                               errorBuilder: (_,__,___) => Container(width: 100, height: 60, color: Colors.grey[800])),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(offer.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text(offer.description, maxLines: 1, overflow: TextOverflow.ellipsis, 
                                     style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                            onPressed: () => ref.read(adminServiceProvider).deleteOffer(offer.id),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
              child: const Text('DONE'),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddOfferDialog(BuildContext context, WidgetRef ref) {
    final titleC = TextEditingController();
    final descC = TextEditingController();
    final urlC = TextEditingController();
    final valueC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Promo Banner'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleC, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: descC, decoration: const InputDecoration(labelText: 'Description')),
              TextField(controller: urlC, decoration: const InputDecoration(labelText: 'Image URL')),
              TextField(controller: valueC, decoration: const InputDecoration(labelText: 'Discount Value (%)'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
               ref.read(adminServiceProvider).addOffer(OfferModel(
                  id: '',
                  title: titleC.text,
                  description: descC.text,
                  imageUrl: urlC.text,
                  offerType: 'percentage',
                  value: double.tryParse(valueC.text) ?? 0.0,
                  expiryDate: DateTime.now().add(const Duration(days: 30)),
               ));
               Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class ShopManagementScreen extends ConsumerWidget {
  const ShopManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Shop Management', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildManagementCard(
            context,
            title: 'All Shops',
            subtitle: 'View and manage all registered stores',
            icon: Icons.storefront_rounded,
            color: const Color(0xFF6366F1),
            onTap: () => context.push('/admin/all-shops'),
          ),
          _buildManagementCard(
            context,
            title: 'Create Shop',
            subtitle: 'Register a new store and assign vendor',
            icon: Icons.add_business_rounded,
            color: const Color(0xFF10B981),
            onTap: () => context.push('/admin/add-vendor'),
          ),
          _buildManagementCard(
            context,
            title: 'Assign Vendor',
            subtitle: 'Link a vendor to an existing shop',
            icon: Icons.person_add_alt_1_rounded,
            color: const Color(0xFFF59E0B),
            onTap: () => _showAssignVendorDialog(context, ref),
          ),
          _buildManagementCard(
            context,
            title: 'Shop Categories',
            subtitle: 'Manage marketplace store categories',
            icon: Icons.category_rounded,
            color: const Color(0xFF8B5CF6),
            onTap: () => context.push('/admin/categories'),
          ),
          _buildManagementCard(
            context,
            title: 'Promo Banners',
            subtitle: 'Manage home screen promotional offers',
            icon: Icons.photo_library_rounded,
            color: const Color(0xFF06B6D4),
            onTap: () => _showPromoBannersSheet(context, ref),
          ),
          _buildManagementCard(
            context,
            title: 'Inventory Audit',
            subtitle: 'Monitor stock levels across all stores',
            icon: Icons.inventory_2_rounded,
            color: const Color(0xFF10B981),
            onTap: () => context.push('/admin/all-shops'), // Could link to a stock audit page
          ),
          _buildManagementCard(
            context,
            title: 'Platform Insights',
            subtitle: 'Real-time performance distribution',
            icon: Icons.analytics_rounded,
            color: const Color(0xFFEF4444),
            onTap: () => context.push('/admin/analytics'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showAssignVendorDialog(BuildContext context, WidgetRef ref) {
    String? selectedVendorId;
    String? selectedShopId;
    String? selectedShopName;

    final vendorsAsync = ref.watch(allVendorsProvider);
    final shopsAsync = ref.watch(allShopsProvider);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Assign Vendor to Shop'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              vendorsAsync.when(
                data: (vendors) {
                  final availableVendors = vendors.where((v) => v.shopId == null).toList();
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Select Vendor'),
                    items: availableVendors.map((v) => DropdownMenuItem(value: v.uid, child: Text(v.name))).toList(),
                    onChanged: (v) => setState(() => selectedVendorId = v),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, s) => Text('Error: $e'),
              ),
              const SizedBox(height: 16),
              shopsAsync.when(
                data: (shops) => DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Select Shop'),
                  items: shops.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedShopId = v;
                      selectedShopName = shops.firstWhere((s) => s.id == v).name;
                    });
                  },
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, s) => Text('Error: $e'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: (selectedVendorId == null || selectedShopId == null) ? null : () async {
                await ref.read(adminServiceProvider).assignVendorToShop(selectedVendorId!, selectedShopId!, selectedShopName!);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vendor assigned successfully!')));
                }
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPromoBannersSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PromoBannersSheet(),
    );
  }

  Widget _buildManagementCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
        ),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface)),
          subtitle: Text(subtitle, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13)),
          trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.3)),
        ),
      ),
    );
  }
}

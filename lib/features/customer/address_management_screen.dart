import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../models/address_model.dart';
import '../../theme/app_colors.dart';

class AddressManagementScreen extends ConsumerWidget {
  const AddressManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(customerAddressesProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Saved Locations', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: colorScheme.onBackground),
          onPressed: () => context.canPop() ? context.pop() : context.go('/customer/profile'),
        ),
      ),
      body: addressesAsync.when(
        data: (addresses) {
          if (addresses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: colorScheme.surface, 
                        shape: BoxShape.circle,
                        boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 40)] : null,
                      ),
                      child: Icon(Icons.location_off_rounded, size: 64, color: colorScheme.primary.withOpacity(0.2)),
                    ),
                    const SizedBox(height: 32),
                    Text('No addresses found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: colorScheme.onBackground)),
                    const SizedBox(height: 12),
                    Text(
                      'Add your delivery locations to speed up your checkout process.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.w500, height: 1.5),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed: () => _showAddressDialog(context, ref),
                      icon: const Icon(Icons.add_location_alt_rounded, size: 20),
                      label: const Text('ADD NEW ADDRESS'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            itemCount: addresses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _AddressTile(address: addresses[index]),
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: colorScheme.primary)),
        error: (e, s) => Center(child: Text('Error: $e', style: TextStyle(color: colorScheme.error))),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddressDialog(context, ref),
        backgroundColor: colorScheme.primary,
        child: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
      ),
    );
  }

  void _showAddressDialog(BuildContext context, WidgetRef ref, {AddressModel? address}) {
    final labelController = TextEditingController(text: address?.label);
    final addressController = TextEditingController(text: address?.fullAddress);
    final cityController = TextEditingController(text: address?.city);
    bool isDefault = address?.isDefault ?? false;
    final colorScheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: BoxDecoration(
            color: isLight ? Colors.white : AppColors.dialog,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          ),
          padding: EdgeInsets.fromLTRB(28, 20, 28, MediaQuery.of(context).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: colorScheme.onSurface.withOpacity(0.1), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 32),
              Text(
                address == null ? 'New Location' : 'Update Address',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: colorScheme.onSurface, letterSpacing: -1),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: labelController,
                decoration: const InputDecoration(
                  hintText: 'Label (e.g. Home, Office)',
                  prefixIcon: Icon(Icons.bookmark_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  hintText: 'Full Delivery Address',
                  prefixIcon: Icon(Icons.location_on_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cityController,
                decoration: const InputDecoration(
                  hintText: 'City',
                  prefixIcon: Icon(Icons.location_city_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: isLight ? AppColors.lightSecondaryBackground : AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Primary Address', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: colorScheme.onSurface)),
                  subtitle: Text('Use as default for orders', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: colorScheme.onSurface.withOpacity(0.5))),
                  value: isDefault,
                  activeColor: colorScheme.primary,
                  onChanged: (v) => setState(() => isDefault = v),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  final user = ref.read(userModelProvider).asData?.value;
                  if (user == null) return;
                  final newAddress = AddressModel(
                    id: address?.id ?? '',
                    label: labelController.text.trim(),
                    fullAddress: addressController.text.trim(),
                    city: cityController.text.trim(),
                    isDefault: isDefault,
                  );
                  if (address == null) {
                    ref.read(customerServiceProvider).addAddress(user.uid, newAddress);
                  } else {
                    ref.read(customerServiceProvider).updateAddress(user.uid, newAddress);
                  }
                  Navigator.pop(context);
                },
                child: Text(address == null ? 'SAVE LOCATION' : 'SAVE CHANGES'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressTile extends ConsumerWidget {
  final AddressModel address;
  const _AddressTile({required this.address});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final bool isHome = address.label.toLowerCase().contains('home');
    final bool isOffice = address.label.toLowerCase().contains('office') || address.label.toLowerCase().contains('work');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)] : null,
        border: address.isDefault 
            ? Border.all(color: colorScheme.primary.withOpacity(0.4), width: 1.5) 
            : (isLight ? Border.all(color: colorScheme.outline.withOpacity(0.05)) : null),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: address.isDefault ? colorScheme.primary.withOpacity(0.1) : (isLight ? AppColors.lightSecondaryBackground : AppColors.background),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isHome ? Icons.home_rounded : isOffice ? Icons.business_center_rounded : Icons.location_on_rounded,
              color: address.isDefault ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.3), 
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      address.label, 
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: colorScheme.onSurface)
                    ),
                    if (address.isDefault) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: const Text('DEFAULT', style: TextStyle(color: AppColors.success, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  address.fullAddress, 
                  style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: colorScheme.onSurface.withOpacity(0.3)),
            color: isLight ? Colors.white : AppColors.dialog,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: colorScheme.onSurface))),
              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
              if (!address.isDefault) PopupMenuItem(value: 'default', child: Text('Set Default', style: TextStyle(color: colorScheme.onSurface))),
            ],
            onSelected: (val) {
              final user = ref.read(userModelProvider).asData?.value;
              if (user == null) return;
              if (val == 'edit') {
                const AddressManagementScreen()._showAddressDialog(context, ref, address: address);
              } else if (val == 'delete') {
                ref.read(customerServiceProvider).deleteAddress(user.uid, address.id);
              } else if (val == 'default') {
                ref.read(customerServiceProvider).setDefaultAddress(user.uid, address.id);
              }
            },
          ),
        ],
      ),
    );
  }
}

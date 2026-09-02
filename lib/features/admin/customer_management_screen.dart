import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/providers.dart';
import '../../models/user_model.dart';

class CustomerManagementScreen extends ConsumerWidget {
  final String searchQuery;
  const CustomerManagementScreen({super.key, this.searchQuery = ''});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(allCustomersProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return customersAsync.when(
      data: (customers) {
        final filtered = customers.where((c) => 
          c.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          c.email.toLowerCase().contains(searchQuery.toLowerCase())
        ).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_search_rounded, size: 64, color: colorScheme.onSurface.withValues(alpha: 0.1)),
                const SizedBox(height: 16),
                Text('No customers found.', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          physics: const BouncingScrollPhysics(),
          itemCount: filtered.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) => _CustomerListTile(customer: filtered[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}

class _CustomerListTile extends ConsumerWidget {
  final UserModel customer;
  const _CustomerListTile({required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isDisabled = customer.status == 'disabled';

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                    backgroundImage: (customer.profilePicture != null && customer.profilePicture!.isNotEmpty)
                        ? NetworkImage(customer.profilePicture!)
                        : null,
                    child: (customer.profilePicture == null || customer.profilePicture!.isEmpty)
                        ? Icon(Icons.person_rounded, color: colorScheme.primary, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: colorScheme.onSurface),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          customer.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customer.phone,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isDisabled ? const Color(0xFFEF4444) : const Color(0xFF10B981)).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          customer.status.toUpperCase(),
                          style: TextStyle(
                            color: isDisabled ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        DateFormat('MMM dd, yyyy').format(customer.createdAt),
                        style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.02),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _QuickAction(
                    icon: Icons.edit_rounded,
                    label: 'EDIT',
                    onTap: () => _showEditDialog(context, ref, customer),
                  ),
                  _QuickAction(
                    icon: Icons.visibility_rounded,
                    label: 'DETAILS',
                    onTap: () => _showDetailsSheet(context, customer),
                  ),
                  _QuickAction(
                    icon: Icons.receipt_long_rounded,
                    label: 'HISTORY',
                    onTap: () => context.push('/admin/user-history/${customer.uid}/${customer.role.name}'),
                  ),
                  _QuickAction(
                    icon: isDisabled ? Icons.check_circle_rounded : Icons.block_rounded,
                    label: isDisabled ? 'ENABLE' : 'DISABLE',
                    color: isDisabled ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    onTap: () {
                      ref.read(adminServiceProvider).updateUserStatus(
                        customer.uid, 
                        isDisabled ? 'active' : 'disabled'
                      );
                    },
                  ),
                  PopupMenuButton<String>(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    icon: Icon(Icons.more_vert_rounded, color: colorScheme.onSurface.withValues(alpha: 0.3)),
                    onSelected: (val) {
                      if (val == 'reset') _showPasswordResetDialog(context, ref, customer);
                      if (val == 'delete') _showDeleteDialog(context, ref, customer);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'reset',
                        child: Row(children: [Icon(Icons.lock_reset_rounded, size: 20), SizedBox(width: 12), Text('Reset Password')]),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red), SizedBox(width: 12), Text('Delete Account', style: TextStyle(color: Colors.red))]),
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

  void _showDetailsSheet(BuildContext context, UserModel customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _UserDetailSheet(user: customer),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, UserModel customer) {
    final nameController = TextEditingController(text: customer.name);
    final phoneController = TextEditingController(text: customer.phone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Customer Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 16),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone Number')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(adminServiceProvider).updateUserDetails(customer.uid, {
                'name': nameController.text.trim(),
                'phone': phoneController.text.trim(),
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showPasswordResetDialog(BuildContext context, WidgetRef ref, UserModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password?'),
        content: Text('Send a password reset email to ${customer.email}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(adminServiceProvider).sendResetPasswordEmail(customer.email);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password reset email sent')),
              );
            },
            child: const Text('Send Email'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, UserModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer?'),
        content: Text('Are you sure you want to delete "${customer.name}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(adminServiceProvider).deleteUser(customer.uid);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _QuickAction({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color ?? colorScheme.onSurface.withValues(alpha: 0.4)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 9, 
                  fontWeight: FontWeight.w900, 
                  color: color ?? colorScheme.onSurface.withValues(alpha: 0.4),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserDetailSheet extends ConsumerWidget {
  final UserModel user;
  const _UserDetailSheet({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: colorScheme.onSurface.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 50,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
            backgroundImage: user.profilePicture != null ? NetworkImage(user.profilePicture!) : null,
            child: user.profilePicture == null ? Icon(Icons.person, size: 50, color: colorScheme.primary) : null,
          ),
          const SizedBox(height: 16),
          Text(user.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          Text(user.role.name.toUpperCase(), style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12)),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              physics: const BouncingScrollPhysics(),
              children: [
                _DetailRow(label: 'Email Address', value: user.email, icon: Icons.email_outlined),
                _DetailRow(label: 'Phone Number', value: user.phone, icon: Icons.phone_outlined),
                _DetailRow(label: 'Status', value: user.status.toUpperCase(), icon: Icons.info_outline, 
                    valueColor: user.status == 'active' ? Colors.green : Colors.orange),
                _DetailRow(label: 'Account Created', value: user.createdAt.toString().split(' ')[0], icon: Icons.calendar_today_outlined),
                if (user.role == UserRole.vendor) 
                  _DetailRow(label: 'Shop ID', value: user.shopId ?? 'Not set', icon: Icons.storefront),
                if (user.role == UserRole.rider) ...[
                   _DetailRow(label: 'Vehicle', value: user.vehicleInfo ?? 'Not set', icon: Icons.directions_bike),
                   _DetailRow(label: 'Rating', value: user.rating.toString(), icon: Icons.star_outline),
                ],
                const SizedBox(height: 32),
                const Text('RECENT ACTIVITY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
                const SizedBox(height: 12),
                _buildActivityList(ref),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
              child: const Text('CLOSE'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList(WidgetRef ref) {
    return Column(
      children: [
        _ActivityItem(title: 'Updated profile picture', time: '2 days ago', icon: Icons.image_outlined),
        _ActivityItem(title: 'Changed contact number', time: '5 days ago', icon: Icons.phone_android),
        _ActivityItem(title: 'Logged in from new device', time: '1 week ago', icon: Icons.security),
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String title;
  final String time;
  final IconData icon;
  const _ActivityItem({required this.title, required this.time, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.3)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(time, style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.3))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  const _DetailRow({required this.label, required this.value, required this.icon, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurface.withValues(alpha: 0.3)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: colorScheme.onSurface.withValues(alpha: 0.3))),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: valueColor ?? colorScheme.onSurface)),
            ],
          ),
        ],
      ),
    );
  }
}

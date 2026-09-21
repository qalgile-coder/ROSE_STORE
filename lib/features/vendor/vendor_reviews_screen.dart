import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/providers.dart';
import '../../models/review_model.dart';
import '../../theme/app_colors.dart';

class VendorReviewsScreen extends ConsumerStatefulWidget {
  const VendorReviewsScreen({super.key});

  @override
  ConsumerState<VendorReviewsScreen> createState() => _VendorReviewsScreenState();
}

class _VendorReviewsScreenState extends ConsumerState<VendorReviewsScreen> {
  int? _filterRating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final reviewsAsync = ref.watch(shopReviewsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Customer Reviews', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
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
          preferredSize: const Size.fromHeight(64),
          child: Container(
            height: 64,
            padding: const EdgeInsets.only(bottom: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              children: [
                _FilterChip(
                  label: 'ALL',
                  isSelected: _filterRating == null,
                  onSelected: () => setState(() => _filterRating = null),
                  colorScheme: colorScheme,
                  isLight: isLight,
                ),
                ...List.generate(5, (index) {
                  final rating = 5 - index;
                  return _FilterChip(
                    label: '$rating STARS',
                    isSelected: _filterRating == rating,
                    onSelected: () => setState(() => _filterRating = rating),
                    colorScheme: colorScheme,
                    isLight: isLight,
                  );
                }),
              ],
            ),
          ),
        ),
      ),
      body: reviewsAsync.when(
        data: (reviews) {
          final filtered = _filterRating == null 
              ? reviews 
              : reviews.where((r) => r.rating.round() == _filterRating).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rate_review_rounded, size: 64, color: colorScheme.onSurface.withOpacity(0.05)),
                  const SizedBox(height: 16),
                  Text(
                    _filterRating == null ? 'No reviews yet.' : 'No reviews with $_filterRating stars.',
                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _ReviewCard(review: filtered[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final ColorScheme colorScheme;
  final bool isLight;

  const _FilterChip({required this.label, required this.isSelected, required this.onSelected, required this.colorScheme, required this.isLight});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onSelected,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : (isLight ? AppColors.lightSecondaryBackground : colorScheme.surface),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(isLight ? 0.5 : 0.05)
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends ConsumerWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.outline.withOpacity(isLight ? 0.5 : 0.05)),
        boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(review.customerName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Row(
                children: List.generate(5, (index) => Icon(
                  Icons.star_rounded,
                  size: 18,
                  color: index < review.rating ? Colors.orange : colorScheme.onSurface.withOpacity(0.05),
                )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(
              'ORDER #${review.orderId.substring(0, 8).toUpperCase()}',
              style: TextStyle(color: colorScheme.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            review.review,
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.8), fontSize: 14, height: 1.5, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          Text(
            DateFormat('MMM dd, yyyy • hh:mm a').format(review.createdAt),
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.3), fontSize: 11, fontWeight: FontWeight.w700),
          ),
          if (review.reply != null && review.reply!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isLight ? AppColors.lightSecondaryBackground : AppColors.premiumDarkSecondaryBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.reply_rounded, size: 14, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('STORE RESPONSE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: colorScheme.primary, letterSpacing: 1)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(review.reply!, style: TextStyle(fontSize: 13, height: 1.4, color: colorScheme.onSurface.withOpacity(0.7), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1, color: colorScheme.outline.withOpacity(0.1)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ReviewActionButton(
                icon: Icons.reply_rounded,
                label: review.reply == null ? 'REPLY' : 'EDIT',
                onTap: () => _showReplyDialog(context, ref, colorScheme),
                color: colorScheme.primary,
              ),
              _ReviewActionButton(
                icon: Icons.flag_rounded,
                label: 'REPORT',
                color: AppColors.error.withValues(alpha: 0.7),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Review report submitted for moderation.'), behavior: SnackBarBehavior.floating),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReplyDialog(BuildContext context, WidgetRef ref, ColorScheme colorScheme) {
    final controller = TextEditingController(text: review.reply);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Response to Customer', style: TextStyle(fontWeight: FontWeight.w900)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Type your message...',
            filled: true,
            fillColor: colorScheme.surface,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              final user = ref.read(userModelProvider).asData?.value;
              if (user?.shopId != null) {
                ref.read(vendorServiceProvider).replyToReview(user!.shopId!, review.id, controller.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(100, 48)),
            child: const Text('SEND REPLY'),
          ),
        ],
      ),
    );
  }
}

class _ReviewActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ReviewActionButton({required this.icon, required this.label, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

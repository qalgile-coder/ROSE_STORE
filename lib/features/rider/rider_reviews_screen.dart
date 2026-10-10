import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../models/review_model.dart';
import '../../theme/app_colors.dart';

class RiderReviewsScreen extends ConsumerWidget {
  const RiderReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final reviewsAsync = ref.watch(riderReviewsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Customer Ratings', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: colorScheme.onSurface),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/rider');
            }
          },
        ),
      ),
      body: reviewsAsync.when(
        data: (reviews) {
          if (reviews.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_outline_rounded, size: 64, color: colorScheme.onSurface.withValues(alpha: 0.05)),
                  const SizedBox(height: 16),
                  Text('No ratings received yet.', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            itemCount: reviews.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _RatingCard(review: reviews[index], colorScheme: colorScheme),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  final ReviewModel review;
  final ColorScheme colorScheme;
  const _RatingCard({required this.review, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(review.customerName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              Row(
                children: List.generate(5, (index) => Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: index < review.rating ? Colors.orange : colorScheme.onSurface.withValues(alpha: 0.1),
                )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            review.review,
            style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 14, height: 1.6, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 12, color: colorScheme.onSurface.withValues(alpha: 0.2)),
              const SizedBox(width: 8),
              Text(
                'Delivered on ${DateFormat('MMM dd, yyyy').format(review.createdAt)}',
                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (review.reply != null && review.reply!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.reply_all_rounded, color: colorScheme.primary, size: 14),
                      const SizedBox(width: 8),
                      Text('YOUR RESPONSE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 9, color: colorScheme.primary, letterSpacing: 1.5)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(review.reply!, style: TextStyle(fontSize: 13, height: 1.5, color: colorScheme.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

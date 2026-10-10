import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/localization.dart';
import '../../models/review_model.dart';
import '../../theme/app_colors.dart';

class ProductReviewsScreen extends ConsumerWidget {
  final String productId;
  final String productName;
  const ProductReviewsScreen({super.key, required this.productId, required this.productName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(productReviewsProvider(productId));
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final bgColor = isLight ? AppColors.lightBackground : AppColors.premiumDarkBackground;
    final textColor = isLight ? AppColors.lightTextPrimary : AppColors.premiumDarkTextPrimary;
    final primaryColor = isLight ? AppColors.lightPrimary : AppColors.premiumDarkPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('customer_reviews'.tr(ref), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textColor)),
            Text(productName, style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.5), fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: reviewsAsync.when(
        data: (reviews) {
          if (reviews.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rate_review_rounded, size: 64, color: textColor.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),
                  Text('no_reviews'.tr(ref), style: TextStyle(color: textColor.withValues(alpha: 0.5), fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: reviews.length,
            separatorBuilder: (_, __) => Divider(color: textColor.withValues(alpha: 0.1), height: 40),
            itemBuilder: (context, index) => _ReviewItem(
              review: reviews[index], 
              textColor: textColor,
              primaryColor: primaryColor,
            ),
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: primaryColor)),
        error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final ReviewModel review;
  final Color textColor;
  final Color primaryColor;
  const _ReviewItem({required this.review, required this.textColor, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(review.customerName, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: textColor)),
            Row(
              children: List.generate(5, (index) => Icon(
                Icons.star_rounded, 
                size: 16, 
                color: index < review.rating ? Colors.orange : textColor.withValues(alpha: 0.1)
              )),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('dd MMM yyyy').format(review.createdAt),
          style: TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          review.review,
          style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 14, height: 1.5, fontWeight: FontWeight.w500),
        ),
        if (review.reply != null && review.reply!.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.reply_rounded, color: primaryColor, size: 16),
                    const SizedBox(width: 8),
                    Text('RESPONSE FROM VENDOR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  review.reply!,
                  style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 13, height: 1.4, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

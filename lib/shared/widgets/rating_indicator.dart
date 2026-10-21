import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class RatingIndicator extends StatelessWidget {
  final double? rating;
  final int? reviewCount;
  final double starSize;
  final TextStyle? textStyle;
  final bool compact;

  const RatingIndicator({
    super.key,
    required this.rating,
    this.reviewCount,
    this.starSize = 14,
    this.textStyle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (rating == null || rating == 0.0) {
      if (compact) {
        return const SizedBox.shrink();
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_border_rounded,
            color: AppColors.textMuted,
            size: starSize,
          ),
          const SizedBox(width: 3),
          Text(
            'Not available',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ],
      );
    }

    String reviewText = '';
    if (reviewCount != null) {
      if (reviewCount! >= 1000) {
        reviewText = '(${(reviewCount! / 1000).toStringAsFixed(1)}k${compact ? '' : ' reviews'})';
      } else {
        reviewText = '($reviewCount${compact ? '' : ' reviews'})';
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.star_rounded,
          color: AppColors.amber,
          size: starSize,
        ),
        const SizedBox(width: 3),
        Text(
          rating!.toStringAsFixed(1),
          style: textStyle ??
              const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
        if (reviewText.isNotEmpty) ...[
          const SizedBox(width: 3),
          Text(
            reviewText,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

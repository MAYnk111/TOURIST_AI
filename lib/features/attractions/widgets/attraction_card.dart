import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/attraction.dart';
import '../../../shared/widgets/rating_indicator.dart';
import '../../../shared/widgets/attraction_image.dart';

class AttractionCard extends StatelessWidget {
  final Attraction attraction;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onSaveToggle;

  const AttractionCard({
    super.key,
    required this.attraction,
    required this.isSaved,
    required this.onTap,
    required this.onSaveToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail Image on Left
            AttractionImage(
              imageUrl: attraction.imageUrl,
              category: attraction.category,
              name: attraction.name,
              width: 90,
              height: 90,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(width: 12),

            // Details in Middle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    attraction.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),

                  // Rating & Review count
                  RatingIndicator(
                    rating: attraction.rating,
                    reviewCount: attraction.reviewCount,
                  ),
                  const SizedBox(height: 6),

                  // Tags
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: attraction.tags.take(2).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#$tag',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 6),

                  // Duration
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        attraction.formattedDuration,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Heart Icon Button on Right
            IconButton(
              icon: Icon(
                isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isSaved ? AppColors.coral : AppColors.textMuted,
                size: 20,
              ),
              onPressed: onSaveToggle,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
              splashRadius: 18,
            ),
          ],
        ),
      ),
    );
  }
}

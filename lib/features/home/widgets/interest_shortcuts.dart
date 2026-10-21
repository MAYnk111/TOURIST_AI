import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class InterestShortcuts extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onSelectCategory;

  const InterestShortcuts({
    super.key,
    required this.selectedCategory,
    required this.onSelectCategory,
  });

  static const List<Map<String, dynamic>> categories = [
    {
      'label': 'Beaches',
      'icon': Icons.beach_access_rounded,
      'bg': Color(0xFFF3E8FF),
      'color': Color(0xFF9333EA),
    },
    {
      'label': 'Adventure',
      'icon': Icons.explore_rounded,
      'bg': Color(0xFFE0F2FE),
      'color': Color(0xFF0284C7),
    },
    {
      'label': 'Nature',
      'icon': Icons.park_rounded,
      'bg': Color(0xFFDCFCE7),
      'color': Color(0xFF16A34A),
    },
    {
      'label': 'Food',
      'icon': Icons.restaurant_rounded,
      'bg': Color(0xFFFFEDD5),
      'color': Color(0xFFEA580C),
    },
    {
      'label': 'History',
      'icon': Icons.account_balance_rounded,
      'bg': Color(0xFFE0E7FF),
      'color': Color(0xFF4F46E5),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final label = cat['label'] as String;
          final isSelected = selectedCategory == label;

          return InkWell(
            onTap: () => onSelectCategory(label),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: cat['bg'] as Color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: cat['color'] as Color, width: 2)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    cat['icon'] as IconData,
                    color: cat['color'] as Color,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

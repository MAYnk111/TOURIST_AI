import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SearchField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onSearchTap;
  final VoidCallback? onClearTap;
  final VoidCallback? onVoiceTap;

  const SearchField({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onSearchTap,
    this.onClearTap,
    this.onVoiceTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = controller?.text.isNotEmpty == true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          textInputAction: TextInputAction.search,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Search destinations, cities, landmarks...',
            hintStyle: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
            prefixIcon: IconButton(
              icon: const Icon(
                Icons.search_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              onPressed: onSearchTap ?? () {
                if (controller != null && controller!.text.trim().isNotEmpty) {
                  onSubmitted?.call(controller!.text.trim());
                }
              },
              tooltip: 'Search',
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasText)
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                    onPressed: onClearTap,
                    tooltip: 'Clear',
                  ),
                IconButton(
                  icon: const Icon(
                    Icons.mic_none_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  onPressed: onVoiceTap,
                  tooltip: 'Voice Search',
                ),
              ],
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }
}

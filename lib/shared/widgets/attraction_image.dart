import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AttractionImage extends StatefulWidget {
  final String? imageUrl;
  final String? category;
  final String? name;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const AttractionImage({
    super.key,
    required this.imageUrl,
    this.category,
    this.name,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  State<AttractionImage> createState() => _AttractionImageState();
}

class _AttractionImageState extends State<AttractionImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  bool _isValidUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final u = url.trim().toLowerCase();
    return u.startsWith('http://') || u.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final br = widget.borderRadius ?? BorderRadius.zero;
    final valid = _isValidUrl(widget.imageUrl);

    Widget content;
    if (!valid) {
      content = _buildPlaceholder();
    } else {
      content = CachedNetworkImage(
        imageUrl: widget.imageUrl!.trim(),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: (ctx, url) => _buildShimmer(),
        errorWidget: (ctx, url, error) => _buildPlaceholder(),
      );
    }

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: br,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: content,
        ),
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: content,
    );
  }

  Widget _buildShimmer() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(_shimmerAnimation.value - 1, 0),
              end: Alignment(_shimmerAnimation.value, 0),
              colors: const [
                Color(0xFFE2E8F0),
                Color(0xFFF8FAFC),
                Color(0xFFE2E8F0),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    final theme = _getCategoryTheme(widget.category);
    final isCompact = (widget.height != null && widget.height! < 120) ||
        (widget.width != null && widget.width! < 120);

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.gradientColors,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background soft glowing icon
          Positioned(
            right: isCompact ? -10 : -15,
            bottom: isCompact ? -10 : -15,
            child: Icon(
              theme.icon,
              size: isCompact ? 56 : 100,
              color: Colors.white.withOpacity(0.12),
            ),
          ),

          // Central icon and badge
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isCompact ? 8 : 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.18),
                ),
                child: Icon(
                  theme.icon,
                  size: isCompact ? 22 : 36,
                  color: Colors.white,
                ),
              ),
              if (!isCompact) ...[
                const SizedBox(height: 8),
                Text(
                  theme.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'No photo available',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  _CategoryTheme _getCategoryTheme(String? category) {
    final cat = (category ?? '').toLowerCase();

    if (cat.contains('beach')) {
      return const _CategoryTheme(
        gradientColors: [Color(0xFF0077B6), Color(0xFF00B4D8)],
        icon: Icons.beach_access_rounded,
        label: 'Beach & Coastal',
      );
    } else if (cat.contains('history') || cat.contains('heritage') || cat.contains('fort') || cat.contains('monument')) {
      return const _CategoryTheme(
        gradientColors: [Color(0xFF78350F), Color(0xFFB45309)],
        icon: Icons.account_balance_rounded,
        label: 'Historic Heritage',
      );
    } else if (cat.contains('nature') || cat.contains('garden') || cat.contains('waterfall') || cat.contains('park')) {
      return const _CategoryTheme(
        gradientColors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
        icon: Icons.park_rounded,
        label: 'Nature & Scenery',
      );
    } else if (cat.contains('culture') || cat.contains('temple') || cat.contains('museum') || cat.contains('art')) {
      return const _CategoryTheme(
        gradientColors: [Color(0xFF4A154B), Color(0xFF7B2CBF)],
        icon: Icons.museum_rounded,
        label: 'Art & Culture',
      );
    } else if (cat.contains('food') || cat.contains('dining') || cat.contains('restaurant') || cat.contains('cafe')) {
      return const _CategoryTheme(
        gradientColors: [Color(0xFF9A3412), Color(0xFFEA580C)],
        icon: Icons.restaurant_rounded,
        label: 'Food & Dining',
      );
    } else if (cat.contains('adventure') || cat.contains('trek') || cat.contains('hill') || cat.contains('sport')) {
      return const _CategoryTheme(
        gradientColors: [Color(0xFF0F766E), Color(0xFF0D9488)],
        icon: Icons.explore_rounded,
        label: 'Outdoor Adventure',
      );
    } else if (cat.contains('shop') || cat.contains('market') || cat.contains('bazaar')) {
      return const _CategoryTheme(
        gradientColors: [Color(0xFF9D174D), Color(0xFFBE185D)],
        icon: Icons.shopping_bag_rounded,
        label: 'Market & Shopping',
      );
    }

    return const _CategoryTheme(
      gradientColors: [Color(0xFF334155), Color(0xFF64748B)],
      icon: Icons.place_rounded,
      label: 'Attraction',
    );
  }
}

class _CategoryTheme {
  final List<Color> gradientColors;
  final IconData icon;
  final String label;

  const _CategoryTheme({
    required this.gradientColors,
    required this.icon,
    required this.label,
  });
}

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Raster logo shipped under `assets/branding/calbalance_logo.png`.
///
/// Optional [maxWidth] avoids overflow in narrow app bars. For best results use a
/// PNG with tight crop or transparent margins, or an SVG if you add `flutter_svg`.
class CalBalanceLogo extends StatelessWidget {
  const CalBalanceLogo({
    super.key,
    this.height = 56,
    this.maxWidth,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  });

  final double height;
  final double? maxWidth;
  final BoxFit fit;
  final Alignment alignment;

  static const assetPath = 'assets/branding/calbalance_logo.png';

  @override
  Widget build(BuildContext context) {
    final fallback = _CalBalanceTextFallback(height: height, maxWidth: maxWidth);
    if (maxWidth == null) {
      return Image.asset(
        assetPath,
        height: height,
        fit: fit,
        alignment: alignment,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    return SizedBox(
      height: height,
      width: maxWidth,
      child: Image.asset(
        assetPath,
        fit: fit,
        alignment: alignment,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

/// Stylised wordmark when the PNG is missing (e.g. hot reload before pub get).
class _CalBalanceTextFallback extends StatelessWidget {
  const _CalBalanceTextFallback({required this.height, this.maxWidth});

  final double height;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final fs = (height * 0.36).clamp(18.0, 40.0);
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Cal',
          style: TextStyle(
            fontSize: fs,
            fontWeight: FontWeight.w800,
            color: AppColors.neutral900,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          'Balance',
          style: TextStyle(
            fontSize: fs,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.sky
                : AppColors.skyDark,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
    if (maxWidth == null) return row;
    return SizedBox(
      width: maxWidth,
      child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.center, child: row),
    );
  }
}

/// Compact brand row: logo + optional subtitle for app bars / drawers.
class CalBalanceBrandBar extends StatelessWidget {
  const CalBalanceBrandBar({
    super.key,
    this.logoHeight = 36,
    this.showSubtitle = true,
  });

  final double logoHeight;
  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        CalBalanceLogo(height: logoHeight),
        if (showSubtitle) ...[
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Nutrición y balance',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

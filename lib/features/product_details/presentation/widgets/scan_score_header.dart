part of 'scan_result_widgets.dart';

/// Scanned product identity presentation component.

class ScanScoreHeader extends StatelessWidget {
  const ScanScoreHeader({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final imageUrl = scanData.displayImageUrl;
    final band = GutScoreBand.fromScore(scanData.score);
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final size = 104.w;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: t.cardBackground,
            borderRadius: BorderRadius.circular(BentoMetrics.radius.w * 0.75),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular((BentoMetrics.radius.w * 0.75) - 1.2),
            child: hasImage
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                      color: band.color.withValues(alpha: 0.08),
                      child: Center(
                        child: SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: CircularProgressIndicator(strokeWidth: 2, color: band.color),
                        ),
                      ),
                    ),
                    errorWidget: (_, _, _) => _fallbackTile(band.color, size),
                  )
                : _fallbackTile(band.color, size),
          ),
        ),
        Gap.w14,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (scanData.brand.isNotEmpty) ...[
                Text(
                  scanData.brand.toUpperCase(),
                  style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: (BentoMetrics.eyebrowSize * 0.95).sp, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: t.textSecondary),
                ),
                Gap.h6,
              ],
              Text(
                scanData.productName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: InsightBentoTheme.fontFamily,
                  fontSize: (BentoMetrics.titleWideSize * 1.05).sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: BentoMetrics.titleWideTracking,
                  height: 1.2,
                  color: t.textPrimary,
                ),
              ),
              Gap.h10,
              Wrap(
                spacing: 6.w,
                runSpacing: 6.h,
                children: [
                  if (scanData.nutriscore != null) ProductDetailHeaderTag(label: _nutriLabel(scanData.nutriscore!), color: _nutriColor(scanData.nutriscore!)),
                  if (scanData.novaGroup != null) ProductDetailHeaderTag(label: _novaLabel(scanData.novaGroup!), color: _novaColor(context, scanData.novaGroup!)),
                  if (scanData.isOrganic == true) ProductDetailHeaderTag(label: 'Organic', color: t.positive, icon: AppIcons.leaf),
                  if (scanData.servingSize != null && scanData.servingSize!.isNotEmpty) ProductDetailHeaderTag(label: _formatServingSize(scanData.servingSize!), color: t.textSecondary),
                  if (scanData.category != null && scanData.category!.isNotEmpty && scanData.category != 'food' && scanData.category != 'meal')
                    ProductDetailHeaderTag(label: _formatCategory(scanData.category!), color: t.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _nutriLabel(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
        return 'Great Nutrition';
      case 'B':
        return 'Good Nutrition';
      case 'C':
        return 'Okay Nutrition';
      case 'D':
        return 'Fair Nutrition';
      case 'E':
        return 'Poor Nutrition';
      default:
        return 'Nutri-Score $grade';
    }
  }

  String _novaLabel(String group) {
    switch (group) {
      case '1':
        return 'Unprocessed';
      case '2':
        return 'Lightly Processed';
      case '3':
        return 'Processed';
      case '4':
        return 'Ultra-Processed';
      default:
        return 'NOVA $group';
    }
  }

  String _formatServingSize(String serving) {
    final s = serving.trim();
    if (s.toLowerCase().contains('serving') && s.contains('(') && s.contains(')')) {
      final match = RegExp(r'\(([^)]+)\)').firstMatch(s);
      if (match != null) {
        return 'Serving: ${_capitalizeWords(match.group(1)!)}';
      }
    }
    if (RegExp(r'^\d+\s*g$', caseSensitive: false).hasMatch(s)) {
      return '${s.replaceAll(RegExp(r'\s+'), '').toLowerCase()} Serving';
    }
    return _capitalizeWords(s);
  }

  String _capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  String _formatCategory(String cat) {
    if (cat.isEmpty) return '';
    return cat[0].toUpperCase() + cat.substring(1).toLowerCase();
  }

  Color _nutriColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
        return const Color(0xFF059669);
      case 'B':
        return const Color(0xFF10B981);
      case 'C':
        return const Color(0xFFF59E0B);
      case 'D':
        return const Color(0xFFEA580C);
      case 'E':
        return const Color(0xFFDC2626);
      default:
        return Colors.grey;
    }
  }

  Color _novaColor(BuildContext context, String group) {
    final t = context.bentoTheme;
    switch (group) {
      case '1':
        return t.positive;
      case '2':
        return const Color(0xFF0284C7);
      case '3':
        return AppPalette.orange;
      case '4':
        return t.negative;
      default:
        return Colors.grey;
    }
  }

  Widget _fallbackTile(Color color, double size) => Container(
    width: size,
    height: size,
    color: color.withValues(alpha: 0.1),
    child: Center(
      child: Icon(AppIcons.salad, color: color, size: (size * 0.36).sp),
    ),
  );
}

/// 🌟 Section 2: Score gauge + band + personalized "here's why" + expandable breakdown.

part of 'scan_detail_sections.dart';

/// Scan detail card surface component.

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(AppSizes.r16),
        border: Border.all(color: scheme.borderSubtle),
      ),
      child: child,
    );
  }
}

// -----------------------------------------------------------------------------
// Scores & grades
// -----------------------------------------------------------------------------


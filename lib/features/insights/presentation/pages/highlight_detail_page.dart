part of 'highlight_detail_screen.dart';

/// Highlight detail page presentation.

class HighlightDetailScreen extends StatelessWidget {
  const HighlightDetailScreen({super.key, required this.args});

  final HighlightDetailArgs args;

  bool get _isTrigger => (args.chartType ?? '').toLowerCase() == 'trigger';

  @override
  Widget build(BuildContext context) {
    if (_isTrigger) {
      return _buildTriggerDetail(context);
    }
    return _buildHealingTrendDetail(context);
  }

}

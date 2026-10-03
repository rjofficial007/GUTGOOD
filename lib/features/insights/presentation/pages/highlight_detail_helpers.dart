part of 'highlight_detail_screen.dart';

/// Provider lookup used by highlight-detail presentation sections.

AIInsight? _highlightInsightOf(BuildContext context) {
    try {
      return context.read<InsightsNotifier>().latestInsight;
    } on ProviderNotFoundException {
      return null;
    }
  }

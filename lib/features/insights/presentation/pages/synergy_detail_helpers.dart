part of 'synergy_detail_screen.dart';

/// Synergy provider lookup helper.

AIInsight? _synergyLatestInsight(BuildContext context) {
    try {
      return context.read<InsightsNotifier>().latestInsight;
    } on ProviderNotFoundException {
      return null;
    }
  }


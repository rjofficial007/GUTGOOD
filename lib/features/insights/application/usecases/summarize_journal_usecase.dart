import 'package:gutgood/core/ai/client/ai_client.dart';
import 'package:gutgood/core/utils/logger_service.dart';

/// Condenses a large chronological journal into a high-level trend summary.
/// This prevents token inflation in the main analysis prompt by providing
/// summarized context for older data.
class SummarizeJournalUseCase {
  const SummarizeJournalUseCase({required AiClient aiService})
    : _aiService = aiService;

  final AiClient _aiService;

  Future<String?> execute(String rawJournal) async {
    if (rawJournal.isEmpty || rawJournal.length < 500) {
      // Don't bother summarizing very small journals; just return raw or null
      return null;
    }

    try {
      AppLogger.ai(
        'Summarizing historical journal (${rawJournal.length} chars)',
      );

      final prompt =
          '''
Summarize the following Gut Health Journal entries into a compact 2-3 paragraph
overview focusing ONLY on repeating patterns, significant symptom clusters,
and overall gut score trends.

Do not list individual events. Use professional, clinical language.

JOURNAL:
$rawJournal
''';

      return await _aiService.generateContent(
        prompt: prompt,
        usageType: 'system',
      );
    } catch (e) {
      AppLogger.error('SummarizeJournalUseCase: Failed', error: e);
      return null;
    }
  }
}

import 'package:gutgood/core/models/chat/chat_message.dart';
import 'package:gutgood/core/models/scans/scan_result_details.dart';

/// Pure prompt-context formatting used by Chat workflows.
///
/// The builder knows only about chat/domain model data. It does not perform
/// network calls, persistence, or UI work, which keeps context-window policy
/// independently testable.
abstract final class ChatPromptContext {
  const ChatPromptContext._();

  /// Formats entity names salvaged from windowed-out messages. Each category
  /// is capped so pinned context remains a fixed small cost regardless of
  /// conversation length.
  static String? buildPinnedEntities(List<ChatMessage> dropped) {
    const maxFoods = 8;
    const maxSymptoms = 6;
    const maxScans = 6;

    final foods = <String>[];
    final symptoms = <String>[];
    final scans = <String>[];
    final seen = <String>{};

    void add(List<String> bucket, int cap, String raw) {
      final name = raw.trim();
      if (name.isEmpty || bucket.length >= cap) return;
      if (seen.add(name.toLowerCase())) bucket.add(name);
    }

    for (final message in dropped) {
      for (final food in message.foodMentions) {
        add(foods, maxFoods, food);
      }
      for (final meal in message.mealLogs) {
        for (final item in meal.items) {
          add(foods, maxFoods, item);
        }
      }
      for (final symptom in message.symptomMentions) {
        add(symptoms, maxSymptoms, symptom);
      }
      final product = message.scanData?.productName;
      if (product != null) add(scans, maxScans, product);
    }

    if (foods.isEmpty && symptoms.isEmpty && scans.isEmpty) return null;

    final lines = <String>[];
    if (foods.isNotEmpty) lines.add('foods: ${foods.join(', ')}');
    if (symptoms.isNotEmpty) lines.add('symptoms: ${symptoms.join(', ')}');
    if (scans.isNotEmpty) lines.add('scans: ${scans.join(', ')}');
    return lines.join('\n');
  }

  /// Builds the grounded "see more swaps" fragment, preserving the existing
  /// barcode/nutriscore echo instruction used by the AI prompt.
  static String swapsGroundingFragment(String userText, List<ProductSwap> grounded) {
    final items = grounded
        .map((swap) {
          final grade = (swap.nutriscore == null || swap.nutriscore!.isEmpty) ? '?' : swap.nutriscore!;
          final code = (swap.barcode == null || swap.barcode!.isEmpty) ? '?' : swap.barcode!;
          return '${swap.title} (grade $grade, barcode $code)';
        })
        .join('; ');
    return '$userText\n\n(REAL PRODUCT DATA — emit exactly 3 swap objects, one per product below, and copy each "barcode" and "nutriscore" value into its swap object: $items)';
  }
}

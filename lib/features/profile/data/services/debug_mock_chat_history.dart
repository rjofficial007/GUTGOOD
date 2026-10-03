part of 'debug_mock_data_service.dart';

/// Debug chat-history fixture generation.

extension DebugMockChatHistory on DebugMockDataService {
  Future<void> _seedMockChatHistory(DateTime now) async {
    AppLogger.mock('Seeding mock chat history...');
    final msg1Id = const Uuid().v4();
    final msg2Id = const Uuid().v4();

    // 1. User asks about a meal
    await _chatFirestoreService.saveMessage(
      ChatMessage(
        localId: msg1Id,
        role: 'user',
        text: 'I just had some Greek yogurt with blueberries for breakfast. How is that for my gut?',
        createdAt: now.subtract(const Duration(minutes: 15)),
        source: 'chat',
      ),
    );

    // 2. AI responds with analysis
    await _chatFirestoreService.saveMessage(
      ChatMessage(
        localId: msg2Id,
        role: 'ai',
        text:
            'Great choice! Greek yogurt is excellent for your gut. It provides live probiotic cultures that support your microbiome, and the blueberries add a nice dose of antioxidants and gentle fiber. \n\nI\'ve logged this as a positive meal for you.',
        createdAt: now.subtract(const Duration(minutes: 14)),
        source: 'chat',
        foodMentions: const ['Greek Yogurt', 'Blueberries'],
      ),
    );

    // 3. User asks about bloating
    final msg3Id = const Uuid().v4();
    await _chatFirestoreService.saveMessage(
      ChatMessage(localId: msg3Id, role: 'user', text: 'I feel a bit bloated after that pizza I had last night. Any advice?', createdAt: now.subtract(const Duration(minutes: 5)), source: 'chat'),
    );

    // 4. AI responds with symptom logging and advice
    final msg4Id = const Uuid().v4();
    await _chatFirestoreService.saveMessage(
      ChatMessage(
        localId: msg4Id,
        role: 'ai',
        text:
            'I\'m sorry to hear you\'re feeling uncomfortable. Bloating after pepperoni pizza is a pattern we\'ve noticed in your logs. \n\nTry drinking some warm ginger tea or taking a short walk to help with digestion. I\'ve noted the bloating in your symptoms.',
        createdAt: now.subtract(const Duration(minutes: 4)),
        source: 'chat',
        symptomMentions: const ['Bloating'],
      ),
    );
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/features/chat/domain/services/chat_safety_guardrails.dart';

void main() {
  test('appends the existing disclaimer for restricted medical claims', () {
    const response = 'I can diagnose this condition and recommend a treatment.';

    final guarded = ChatSafetyGuardrails.apply(response);

    expect(guarded, startsWith(response));
    expect(guarded, contains('**Disclaimer:**'));
    expect(guarded, contains('not a medical diagnosis'));
  });

  test('does not duplicate an existing disclaimer', () {
    const response = 'Please speak with a clinician. **Disclaimer:** already present.';

    expect(ChatSafetyGuardrails.apply(response), response);
  });

  test('leaves ordinary assistant responses unchanged', () {
    const response = 'Try adding a short walk after lunch and keep a note of symptoms.';

    expect(ChatSafetyGuardrails.apply(response), response);
  });
}

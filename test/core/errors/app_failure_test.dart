import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/errors/app_failure.dart';

void main() {
  test('keeps a stable category and original cause', () {
    final cause = StateError('backend unavailable');
    final failure = AppFailure.fromError(cause, type: FailureType.backend);

    expect(failure.type, FailureType.backend);
    expect(failure.cause, same(cause));
    expect(failure.message, contains('backend unavailable'));
    expect(failure.isConnectivityFailure, isFalse);
  });

  test('treats network and timeout categories as connectivity failures', () {
    expect(const AppFailure(type: FailureType.network, message: 'offline').isConnectivityFailure, isTrue);
    expect(const AppFailure(type: FailureType.timeout, message: 'timed out').isConnectivityFailure, isTrue);
    expect(const AppFailure(type: FailureType.parsing, message: 'bad payload').isConnectivityFailure, isFalse);
  });
}

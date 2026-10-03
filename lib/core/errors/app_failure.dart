/// Broad failure categories shared at application boundaries.
///
/// The type is intentionally independent of Firebase, Dio, Flutter, and
/// platform SDKs. Adapters classify their concrete exceptions before exposing
/// this value to presentation state or use-case callers.
enum FailureType { network, timeout, authentication, backend, parsing, validation, permission, unknown }

/// A structured, testable representation of an operation failure.
///
/// Existing UI copy can remain owned by the current feature while state and
/// telemetry retain a stable category and the original cause for diagnostics.
class AppFailure implements Exception {
  const AppFailure({required this.type, required this.message, this.cause, this.stackTrace});

  factory AppFailure.fromError(Object error, {required FailureType type, StackTrace? stackTrace}) => AppFailure(type: type, message: error.toString(), cause: error, stackTrace: stackTrace);

  final FailureType type;
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  bool get isConnectivityFailure => type == FailureType.network || type == FailureType.timeout;

  @override
  String toString() => 'AppFailure(type: $type, message: $message)';
}

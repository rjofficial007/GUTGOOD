/// Thrown when the server-side free-tier gate rejects the request (HTTP 429).
/// The UI maps this to the paywall. The backend owns the numeric counters
/// (daily_usage is server-write-locked), but premium status itself is
/// client-authoritative by product decision, so these limits are a soft
/// paywall rather than a tamper-proof boundary — see docs/ACCEPTED_RISKS.md
/// R1–R3.
class AiQuotaExceededException implements Exception {
  const AiQuotaExceededException({required this.type, this.message = 'Daily free limit reached.'});
  final String type; // 'chat' | 'scan'
  final String message;

  @override
  String toString() => 'AiQuotaExceededException($type): $message';
}

/// Generic AI proxy failure (network, upstream, or protocol errors).
class AiServiceException implements Exception {
  const AiServiceException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => 'AiServiceException($statusCode): $message';
}

/// The caller has no active Firebase session to authenticate the proxy with.
class AiAuthException implements Exception {
  const AiAuthException();

  @override
  String toString() => 'AiAuthException: no authenticated user.';
}


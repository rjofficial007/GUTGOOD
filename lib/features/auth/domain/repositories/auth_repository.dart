import 'package:gutgood/features/auth/domain/entities/auth_user.dart';

/// Thrown when an anonymous user's chosen credential (Google/Apple/Email)
/// already belongs to a different, existing permanent account. The UI layer
/// should present a merge-confirmation prompt (keep guest data + merge into
/// the existing account, vs. simply log into the existing account and
/// discard the current guest session) — see [AuthRepository.confirmMerge].
class AuthMergeConflictException implements Exception {
  AuthMergeConflictException({
    required this.anonymousUid,
    required this.permanentUid,
    required this.email,
    this.attemptedProvider,
  });
  final String anonymousUid;
  final String permanentUid;
  final String email;
  final String? attemptedProvider;

  @override
  String toString() => 'AuthMergeConflictException: Conflict for $email';
}

/// Thrown when a sign-in method (Google/Apple/Email/EmailLink) is invoked
/// while a *permanent* (non-anonymous) account is already active.
///
/// Without this guard, Firebase would silently switch the active session to
/// a different account the moment the new credential resolves — the user's
/// current data would still exist on disk, but every subsequent read/write
/// would be scoped to the new uid, which is indistinguishable from data loss
/// from the user's point of view.
///
/// The UI layer should catch this and prompt the user to sign out of
/// [currentEmail] / [currentUid] first before switching accounts, rather
/// than attempting the new sign-in silently.
class AuthAlreadySignedInException implements Exception {
  AuthAlreadySignedInException({
    required this.currentUid,
    required this.currentEmail,
    required this.attemptedProvider,
  });
  final String currentUid;
  final String? currentEmail;
  final String attemptedProvider;

  @override
  String toString() =>
      'AuthAlreadySignedInException: Already signed in as '
      '${currentEmail ?? currentUid}; blocked new "$attemptedProvider" sign-in attempt.';
}

/// Thrown by [AuthRepository.deleteAccount] when Firebase rejects the
/// destructive operation because the user's sign-in is not "recent" enough
/// (`requires-recent-login`). The UI layer should catch this and prompt the
/// user to re-authenticate (e.g. via [AuthRepository.reauthenticateWithPassword]
/// or [AuthRepository.reauthenticateWithProvider]) before retrying the delete.
class ReauthenticationRequiredException implements Exception {
  ReauthenticationRequiredException({this.provider});

  /// The provider id (e.g. `google.com`, `apple.com`, `password`) the user
  /// originally signed in with, if known, so the UI can decide which
  /// re-authentication flow to present.
  final String? provider;

  @override
  String toString() => 'ReauthenticationRequiredException(provider: $provider)';
}

abstract class AuthRepository {
  Stream<AuthUser?> get authStateChanges;
  Stream<bool> get isMerging;
  AuthUser? get currentUser;
  Future<AuthUser?> signInAnonymously();
  Future<AuthUser?> signInWithGoogle();
  Future<AuthUser?> signInWithApple();
  Future<void> sendSignInLinkToEmail(String email);
  Future<AuthUser?> signInWithEmailLink(String email, String emailLink);
  Future<AuthUser?> signInWithEmailAndPassword(String email, String password);
  Future<AuthUser?> signUpWithEmailAndPassword(String email, String password);
  Future<void> sendPasswordResetEmail(String email);
  Future<AuthUser?> linkWithGoogle();
  Future<AuthUser?> linkWithApple();
  Future<void> confirmMerge(String anonymousUid, String permanentUid);
  Future<void> abandonMerge();
  Future<void> signOut();

  /// Deletes the current user's account.
  ///
  /// Firebase requires a "recent" sign-in for this destructive operation. If
  /// the current session is stale, this throws [ReauthenticationRequiredException]
  /// instead of silently failing (or, in providers where `delete()` doesn't
  /// enforce this, leaving the Firestore/Storage cleanup 3-4 steps ahead of an
  /// auth deletion that never actually happened). Callers should catch that
  /// exception, prompt for re-authentication via [reauthenticateWithPassword]
  /// or [reauthenticateWithProvider], then call [deleteAccount] again.
  Future<void> deleteAccount();

  /// Re-authenticates the current user with their email/password credential.
  /// Required before [deleteAccount] can succeed if the provider is `password`
  /// and the session is stale.
  Future<void> reauthenticateWithPassword(String password);

  /// Re-authenticates the current user with a fresh Google or Apple
  /// credential (re-runs the native sign-in flow). Required before
  /// [deleteAccount] can succeed if the provider is `google.com`/`apple.com`
  /// and the session is stale.
  Future<void> reauthenticateWithProvider(String providerId);

  Future<void> updateDisplayName(String name);
}

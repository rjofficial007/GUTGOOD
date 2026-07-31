import 'package:gutgood/features/auth/domain/entities/auth_user.dart';

/// Thrown when an anonymous user's chosen credential (Google/Apple/Email)
/// already belongs to a different, existing permanent account. The UI layer
/// should present a merge-confirmation prompt (keep guest data + merge into
/// the existing account, vs. simply log into the existing account and
/// discard the current guest session) — see [AuthRepository.confirmMerge].
class AuthMergeConflictException implements Exception {
  final String anonymousUid;
  final String permanentUid;
  final String email;
  final String? attemptedProvider;

  AuthMergeConflictException({required this.anonymousUid, required this.permanentUid, required this.email, this.attemptedProvider});

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
  final String currentUid;
  final String? currentEmail;
  final String attemptedProvider;

  AuthAlreadySignedInException({required this.currentUid, required this.currentEmail, required this.attemptedProvider});

  @override
  String toString() =>
      'AuthAlreadySignedInException: Already signed in as '
      '${currentEmail ?? currentUid}; blocked new "$attemptedProvider" sign-in attempt.';
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
  Future<void> deleteAccount();
  Future<void> updateDisplayName(String name);
}

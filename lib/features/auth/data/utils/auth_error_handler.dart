import 'package:firebase_auth/firebase_auth.dart';
import 'package:gutgood/features/auth/domain/repositories/auth_repository.dart';

class AuthErrorHandler {
  static String mapException(dynamic e) {
    if (e is AuthMergeConflictException) {
      return 'An account already exists with ${e.email}. Choose whether to merge your progress.';
    }
    if (e is AuthAlreadySignedInException) {
      return 'You\'re already signed in as ${e.currentEmail ?? 'another account'}. Sign out first to switch accounts.';
    }
    if (e is ReauthenticationRequiredException) {
      return 'For your security, please sign in again to confirm this action.';
    }
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'network-request-failed':
          return 'No internet connection. Please check your network and try again.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Invalid email or password. Please try again.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with the same email address but different sign-in credentials.';
        case 'credential-already-in-use':
          return 'This credential is already linked to another user.';
        case 'email-already-in-use':
          return 'This email address is already in use by another account.';
        case 'requires-recent-login':
          return 'This action requires a recent login. Please sign out and sign in again.';
        case 'operation-not-allowed':
          return 'This authentication method is not enabled. Please contact support.';
        case 'too-many-requests':
          return 'Too many requests. Please try again later.';
        case 'invalid-oauth-response':
          return 'The OAuth response was invalid. Please try again.';
        case 'missing-or-invalid-nonce':
          return 'Security validation failed (Invalid Nonce). Please try again.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'invalid-email':
          return 'The email address is badly formatted.';
        case 'weak-password':
          return 'The password is too weak.';
        default:
          return e.message ?? 'An unexpected authentication error occurred.';
      }
    }
    return e.toString();
  }
}

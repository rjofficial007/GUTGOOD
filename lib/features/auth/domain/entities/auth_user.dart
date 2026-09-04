import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  const AuthUser({
    required this.uid,
    this.email,
    this.displayName,
    required this.isAnonymous,
    this.authProvider,
  });
  final String uid;
  final String? email;
  final String? displayName;
  final bool isAnonymous;

  /// The provider id (`google.com`, `apple.com`, `password`, ...) this user
  /// last authenticated with. Used to decide which re-authentication flow to
  /// present (see [ReauthenticationRequiredException]).
  final String? authProvider;

  @override
  List<Object?> get props => [uid, email, displayName, isAnonymous, authProvider];
}

import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  final String uid;
  final String? email;
  final String? displayName;
  final bool isAnonymous;

  const AuthUser({required this.uid, this.email, this.displayName, required this.isAnonymous});

  @override
  List<Object?> get props => [uid, email, displayName, isAnonymous];
}

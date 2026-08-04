import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {

  const AuthUser({required this.uid, this.email, this.displayName, required this.isAnonymous});
  final String uid;
  final String? email;
  final String? displayName;
  final bool isAnonymous;

  @override
  List<Object?> get props => [uid, email, displayName, isAnonymous];
}

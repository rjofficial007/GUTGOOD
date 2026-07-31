import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:gutgood/features/auth/domain/entities/auth_user.dart';

class AuthUserModel extends AuthUser {
  const AuthUserModel({required super.uid, super.email, super.displayName, required super.isAnonymous});

  factory AuthUserModel.fromFirebase(firebase.User user) {
    return AuthUserModel(uid: user.uid, email: user.email, displayName: user.displayName, isAnonymous: user.isAnonymous);
  }
}

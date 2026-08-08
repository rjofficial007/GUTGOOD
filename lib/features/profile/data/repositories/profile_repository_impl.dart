import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:gutgood/core/models/user_profile.dart';
import 'package:gutgood/core/services/firestore/auth_firestore_service.dart';
import 'package:gutgood/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({
    required FirebaseAuth auth,
    required AuthFirestoreService firestoreService,
  }) : _auth = auth,
       _firestoreService = firestoreService;
  final FirebaseAuth _auth;
  final AuthFirestoreService _firestoreService;

  @override
  Future<UserProfile?> getProfile() async {
    if (_auth.currentUser != null) {
      return _firestoreService.getUserMetadata();
    }
    return null;
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    await _firestoreService.saveUserProfile(profile);
  }

  @override
  Future<String?> uploadProfilePicture(File file) async =>
      _firestoreService.uploadProfilePicture(file);
}

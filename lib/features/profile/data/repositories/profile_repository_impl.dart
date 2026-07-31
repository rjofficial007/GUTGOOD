import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:gutgood/core/models/user_profile.dart';
import 'package:gutgood/core/services/firestore_service.dart';
import 'package:gutgood/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final FirebaseAuth _auth;
  final FirestoreService _firestoreService;

  ProfileRepositoryImpl({required FirebaseAuth auth, required FirestoreService firestoreService}) : _auth = auth, _firestoreService = firestoreService;

  @override
  Future<UserProfile?> getProfile() async {
    if (_auth.currentUser != null) {
      return await _firestoreService.getUserMetadata();
    }
    return null;
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    await _firestoreService.saveUserProfile(profile);
  }

  @override
  Future<String?> uploadProfilePicture(File file) async {
    return await _firestoreService.uploadProfilePicture(file);
  }
}

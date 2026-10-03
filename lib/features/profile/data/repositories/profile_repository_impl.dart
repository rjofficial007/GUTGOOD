import 'dart:io';

import 'package:gutgood/features/profile/domain/repositories/profile_repository.dart';
import 'package:gutgood/infrastructure/firebase/firestore/auth_firestore_service.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({required AuthFirestoreService firestoreService}) : _firestoreService = firestoreService;
  final AuthFirestoreService _firestoreService;

  @override
  Future<String?> uploadProfilePicture(File file) async => _firestoreService.uploadProfilePicture(file);
}

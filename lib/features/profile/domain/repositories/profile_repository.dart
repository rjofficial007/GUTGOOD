import 'dart:io';

import 'package:gutgood/core/models/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile?> getProfile();
  Future<void> saveProfile(UserProfile profile);
  Future<String?> uploadProfilePicture(File file);
}

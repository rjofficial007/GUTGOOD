import 'dart:io';

abstract class ProfileRepository {
  Future<String?> uploadProfilePicture(File file);
}

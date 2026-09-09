import 'dart:io';

import 'package:gutgood/core/models/user_profile.dart';

abstract class ProfileRepository {
  Future<String?> uploadProfilePicture(File file);
}

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gutgood/core/constants/api_constants.dart';
import 'package:gutgood/core/di/di_instance.dart';
import 'package:shared_preferences/shared_preferences.dart';

const bool _useFirebaseEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');
String get _emulatorHost => Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';

Future<void> initCoreDI() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  sl
    ..registerLazySingleton(() => sharedPreferences)
    ..registerLazySingleton(() {
      final auth = FirebaseAuth.instance;
      if (_useFirebaseEmulator && kDebugMode) {
        auth.useAuthEmulator(_emulatorHost, 9099);
      }
      return auth;
    })
    ..registerLazySingleton(() {
      final firestore = FirebaseFirestore.instance..settings = const Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED);
      if (_useFirebaseEmulator && kDebugMode) {
        firestore.useFirestoreEmulator(_emulatorHost, 8080);
      }
      return firestore;
    })
    ..registerLazySingleton(() {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      if (_useFirebaseEmulator && kDebugMode) {
        functions.useFunctionsEmulator(_emulatorHost, 5001);
      }
      return functions;
    })
    ..registerLazySingleton(() {
      final storage = FirebaseStorage.instance;
      if (_useFirebaseEmulator && kDebugMode) {
        storage.useStorageEmulator(_emulatorHost, 9199);
      }
      return storage;
    })
    ..registerLazySingleton(() => FirebaseRemoteConfig.instance)
    ..registerLazySingleton(() => GoogleSignIn.instance)
    ..registerLazySingleton(DeviceInfoPlugin.new)
    ..registerLazySingleton(() => Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'User-Agent': ApiConstants.userAgent},
      ),
    ))
    ..registerLazySingleton(FlutterLocalNotificationsPlugin.new);
}

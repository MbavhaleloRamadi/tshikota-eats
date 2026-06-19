import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'constants.dart';

class FirebaseConfig {
  static Future<void> initialize() async {
    // Firestore offline persistence
    FirebaseFirestore.instance.settings = Settings(
      persistenceEnabled: true,
      cacheSizeBytes: AppConstants.firestoreCacheSizeMB * 1024 * 1024,
    );

    // App Check (release only)
    if (kReleaseMode) {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.appAttest,
      );
    }
  }
}

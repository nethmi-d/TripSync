import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

import '../constants/firebase_web_config.dart';

class FirebaseService {
  FirebaseService._();

  static Future<void> initialize() async {
    if (kIsWeb) {
      if (!FirebaseWebConfig.isConfigured) {
        throw StateError(
          'FIREBASE_WEB_APP_ID is required when running TripSync on web.',
        );
      }

      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: FirebaseWebConfig.apiKey,
          appId: FirebaseWebConfig.appId,
          messagingSenderId: FirebaseWebConfig.messagingSenderId,
          projectId: FirebaseWebConfig.projectId,
          authDomain: FirebaseWebConfig.authDomain,
          storageBucket: FirebaseWebConfig.storageBucket,
        ),
      );
      return;
    }

    await Firebase.initializeApp();
  }
}

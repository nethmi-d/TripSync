class FirebaseWebConfig {
  FirebaseWebConfig._();

  static const String apiKey = String.fromEnvironment(
    'FIREBASE_WEB_API_KEY',
    defaultValue: 'AIzaSyCQnKBp2mg4WARCcv_DQoh8A_3rQDZCFYQ',
  );
  static const String appId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
  static const String messagingSenderId = String.fromEnvironment(
    'FIREBASE_WEB_MESSAGING_SENDER_ID',
    defaultValue: '383761795011',
  );
  static const String projectId = String.fromEnvironment(
    'FIREBASE_WEB_PROJECT_ID',
    defaultValue: 'tripsync-ae73b',
  );
  static const String authDomain = String.fromEnvironment(
    'FIREBASE_WEB_AUTH_DOMAIN',
    defaultValue: 'tripsync-ae73b.firebaseapp.com',
  );
  static const String storageBucket = String.fromEnvironment(
    'FIREBASE_WEB_STORAGE_BUCKET',
    defaultValue: 'tripsync-ae73b.firebasestorage.app',
  );

  static bool get isConfigured => appId.isNotEmpty;
}

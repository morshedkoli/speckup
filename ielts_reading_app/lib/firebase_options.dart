import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError('DefaultFirebaseOptions have not been configured for macos.');
      case TargetPlatform.windows:
        throw UnsupportedError('DefaultFirebaseOptions have not been configured for windows.');
      case TargetPlatform.linux:
        throw UnsupportedError('DefaultFirebaseOptions have not been configured for linux.');
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBt2OvUVZHfR1DEqkqARbjRRMwTxkdjffI',
    appId: '1:955029235432:android:184afb5ddeeacb5db54b5d',
    messagingSenderId: '955029235432',
    projectId: 'speakup-ai-prod',
    storageBucket: 'speakup-ai-prod.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCLsloYVCZh2Od9E7YGfg2UaVEklV502OE',
    appId: '1:955029235432:web:bc6059e484c81adbb54b5d',
    messagingSenderId: '955029235432',
    projectId: 'speakup-ai-prod',
    authDomain: 'speakup-ai-prod.firebaseapp.com',
    storageBucket: 'speakup-ai-prod.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBeNcQDemAOZC6jfV1kt7J6F3Rlnkr8wgs',
    appId: '1:955029235432:ios:cca8dd74eccc9c1bb54b5d',
    messagingSenderId: '955029235432',
    projectId: 'speakup-ai-prod',
    storageBucket: 'speakup-ai-prod.firebasestorage.app',
    iosBundleId: 'com.morshed.ieltsReadingApp',
  );

}
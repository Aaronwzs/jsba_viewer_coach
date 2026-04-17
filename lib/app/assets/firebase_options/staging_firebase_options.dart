import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class StagingFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'StagingFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAQccru5stdS807GOAtB_OlLgVDGbe0uyM',
    appId: '1:814632821050:android:e88914980c15971bb47003',
    messagingSenderId: '814632821050',
    projectId: 'juniorshuttlers-stag',
    storageBucket: 'juniorshuttlers-stag.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCZ_ev4OnraRDFSVXrtOs2BL27iTHRR2gY',
    appId: '1:814632821050:ios:2eca2160091c75fcb47003',
    messagingSenderId: '814632821050',
    projectId: 'juniorshuttlers-stag',
    storageBucket: 'juniorshuttlers-stag.firebasestorage.app',
    iosBundleId: 'com.jsba.jsbaApp.stag',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyAq5xjLR3Li0V5oaPp3snkZgbTqNJ10S0U",
    authDomain: "juniorshuttlers-stag.firebaseapp.com",
    projectId: "juniorshuttlers-stag",
    storageBucket: "juniorshuttlers-stag.firebasestorage.app",
    messagingSenderId: "814632821050",
    appId: "1:814632821050:web:7488cb1fc3e2b297b47003",
  );
}

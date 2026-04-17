import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class ProductionFirebaseOptions {
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
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDYiHKSxBDh8PxSl_jM6VSHnWAiIUxGF3A',
    appId: '1:713373958841:android:07f1f8125ab75a88fc9168',
    messagingSenderId: '713373958841',
    projectId: 'juniorshuttlers',
    storageBucket: 'juniorshuttlers.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB5xczWKAkvPBEZEGTSJi4f7dAVRHNgyao',
    appId: '1:713373958841:ios:e460843ef20bd5f4fc9168',
    messagingSenderId: '713373958841',
    projectId: 'juniorshuttlers',
    storageBucket: 'juniorshuttlers.firebasestorage.app',
    iosBundleId: 'com.example.juniorshuttlers',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyARqYAgBdOvXAzsVfDhGnqoqlfU3CHQOVo",
    authDomain: "juniorshuttlers.firebaseapp.com",
    projectId: "juniorshuttlers",
    storageBucket: "juniorshuttlers.firebasestorage.app",
    messagingSenderId: "713373958841",
    appId: "1:713373958841:web:676b5ac9f001ad13fc9168",
  );
}

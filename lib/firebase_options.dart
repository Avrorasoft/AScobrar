import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.windows:
        return windows;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAMy38PqmdL_FqY0g0wxsLBQRmoyydRRZ4',
    appId: '1:111175122961:web:016bdf01fc6828c77db1b0',
    messagingSenderId: '111175122961',
    projectId: 'loan-app-vibola',
    authDomain: 'loan-app-vibola.firebaseapp.com',
    storageBucket: 'loan-app-vibola.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAMy38PqmdL_FqY0g0wxsLBQRmoyydRRZ4',
    appId: '1:111175122961:web:016bdf01fc6828c77db1b0',
    messagingSenderId: '111175122961',
    projectId: 'loan-app-vibola',
    authDomain: 'loan-app-vibola.firebaseapp.com',
    storageBucket: 'loan-app-vibola.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAMy38PqmdL_FqY0g0wxsLBQRmoyydRRZ4',
    appId: '1:111175122961:web:016bdf01fc6828c77db1b0',
    messagingSenderId: '111175122961',
    projectId: 'loan-app-vibola',
    authDomain: 'loan-app-vibola.firebaseapp.com',
    storageBucket: 'loan-app-vibola.firebasestorage.app',
  );
}

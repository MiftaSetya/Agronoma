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
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC9hXfzyU8M4epGrOUz3bGmaySfrk4QJD8',
    appId: '1:25452155703:web:3a414a688f1861b8bd40b2',
    messagingSenderId: '25452155703',
    projectId: 'agronoma-80f5c',
    authDomain: 'agronoma-80f5c.firebaseapp.com',
    storageBucket: 'agronoma-80f5c.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyABw8-TA4wgVuiO2Q5B0SGEpSBE6Ffup2Y',
    appId: '1:25452155703:android:eba28e453a9a3e67bd40b2',
    messagingSenderId: '25452155703',
    projectId: 'agronoma-80f5c',
    storageBucket: 'agronoma-80f5c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyChR5bd4b3wqQkgHHqQrGtRIPCC7IVDHhc',
    appId: '1:25452155703:ios:db832ec5df8234ccbd40b2',
    messagingSenderId: '25452155703',
    projectId: 'agronoma-80f5c',
    storageBucket: 'agronoma-80f5c.firebasestorage.app',
    iosBundleId: 'com.agronoma.frontend',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyChR5bd4b3wqQkgHHqQrGtRIPCC7IVDHhc',
    appId: '1:25452155703:ios:db832ec5df8234ccbd40b2',
    messagingSenderId: '25452155703',
    projectId: 'agronoma-80f5c',
    storageBucket: 'agronoma-80f5c.firebasestorage.app',
    iosBundleId: 'com.agronoma.frontend',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC9hXfzyU8M4epGrOUz3bGmaySfrk4QJD8',
    appId: '1:25452155703:web:6d4c8d1fee7e67fabd40b2',
    messagingSenderId: '25452155703',
    projectId: 'agronoma-80f5c',
    authDomain: 'agronoma-80f5c.firebaseapp.com',
    storageBucket: 'agronoma-80f5c.firebasestorage.app',
  );
}

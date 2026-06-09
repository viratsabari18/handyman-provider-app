import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseConfig {
  static FirebaseOptions get platformOptions {
    if (kIsWeb) {
      // Web
      return const FirebaseOptions(
        appId: '',
        apiKey: '',
        projectId: '',
        messagingSenderId: '',
      );
    } else if (Platform.isIOS || Platform.isMacOS) {
      // iOS and MacOS
      return const FirebaseOptions(
        appId: '',
        apiKey: '',
        projectId: '',
        messagingSenderId: '',
        iosBundleId: '',
      );
    } else {
      // Android
 return const FirebaseOptions(
  appId: '1:258035372869:android:430275901c86cbffa3242c',
  apiKey: 'AIzaSyBCSznTrq6zyD4-4HY9yZUpEkiqEgyoKDA',
  projectId: 'shiber-746d7',
  messagingSenderId: '258035372869',
);
    }
  }
}

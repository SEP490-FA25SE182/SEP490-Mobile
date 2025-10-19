import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // App Check (DEV)
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

  // Đừng block UI nếu sign-in gặp sự cố
  unawaited(_ensureAnonymousSignIn());

  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _ensureAnonymousSignIn() async {
  try {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously()
          .timeout(const Duration(seconds: 10));
    }
  } catch (e) {
    debugPrint('Anonymous sign-in failed (ignored): $e');
    // thử lại sau 2s
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        if (FirebaseAuth.instance.currentUser == null) {
          await FirebaseAuth.instance.signInAnonymously()
              .timeout(const Duration(seconds: 10));
        }
      } catch (_) {}
    });
  }
}

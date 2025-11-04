import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'widget/deep_link_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(androidProvider: AndroidProvider.debug);
  unawaited(_ensureAnonymousSignIn());

  final router = buildRouter();
  final deepLinks = DeepLinkService();
  await deepLinks.init(router);

  runApp(ProviderScope(child: MyApp(router: router)));
}

Future<void> _ensureAnonymousSignIn() async {
  try {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously().timeout(const Duration(seconds: 10));
    }
  } catch (_) {
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        if (FirebaseAuth.instance.currentUser == null) {
          await FirebaseAuth.instance.signInAnonymously().timeout(const Duration(seconds: 10));
        }
      } catch (_) {}
    });
  }
}

// app.dart (rút gọn)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'page/home_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/',                         // <- mặc định vào HomePage
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomePage()),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
    );
  }
}

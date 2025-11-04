import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sep490_mobile/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final router = buildRouter();

    await tester.pumpWidget(
      ProviderScope(
        child: MyApp(router: router),
      ),
    );

    // Đợi router/material build xong
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Trang chủ'), findsOneWidget);
  });
}

// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:_243301011_sengul_sila_sahin_flutter_proje/main.dart';

void main() {
  testWidgets('Nakliyat App UI Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NakliyatApp());

    // Verify that the Login Screen is displayed
    expect(find.text('Nakliyat Sistemi'), findsOneWidget);
    expect(find.text('Giriş Yap'), findsOneWidget);
    expect(find.byIcon(Icons.local_shipping), findsOneWidget);
  });
}

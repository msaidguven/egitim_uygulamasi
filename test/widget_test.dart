// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  // Bu, her testten önce sahte bir Supabase istemcisi oluşturur.
  // Böylece testlerimiz gerçek veritabanına bağlanmaya çalışmaz.
  setUpAll(() async {
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      anonKey: 'test-key',
    );
  });

  testWidgets('Uygulama açıldığında Giriş Yap ekranını gösterir', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const EgitimUygulamasi());

    // "Giriş Yap" başlığını ve butonunu bul.
    expect(
      find.text('Giriş Yap'),
      findsNWidgets(2),
    ); // Biri AppBar'da, diğeri butonda
    expect(find.widgetWithText(ElevatedButton, 'Giriş Yap'), findsOneWidget);
  });
}

// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:stitch/main.dart';

import 'package:stitch/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Smoke test - Verify certificate view loads', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = StorageService();
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(storageService: storageService));

    // Wait for the initialization of StorageService
    await storageService.init();
    await tester.pumpAndSettle();

    // Verify that the default certificate detail is present
    expect(find.text('Ashma Ghimire'), findsOneWidget);
    expect(find.text('2082-646906'), findsOneWidget);
  });
}

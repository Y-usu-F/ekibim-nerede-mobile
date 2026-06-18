import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ekibim_nerede_mobile/main.dart';

void main() {
  // Mock secure storage channel to prevent channel errors during testing
  const channel = MethodChannel('plugins.itrix.com.br/flutter_secure_storage');
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'read') {
        if (methodCall.arguments['key'] == 'app_lang') {
          return 'tr';
        }
        return null;
      }
      return null;
    });
  });

  testWidgets('App renders LoginScreen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EkibimNeredeApp());
    await tester.pumpAndSettle();

    // Verify that the login screen is rendered by looking for the email text field
    expect(find.byType(TextFormField), findsNWidgets(2)); // Email & Password fields
    expect(find.byType(ElevatedButton), findsOneWidget); // Login button
  });
}

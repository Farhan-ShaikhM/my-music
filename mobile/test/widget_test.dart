import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('MyMusicApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MyMusicApp(),
      ),
    );

    // Verify that our app displays "My Music".
    expect(find.text('My Music'), findsAtLeastNWidgets(1));
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iiecm_admin/app/app.dart';

void main() {
  testWidgets('IIECM Admin app loads and presents Login Screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: IIECMAdminApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify presence of institutional branding on Login Screen
    expect(find.text('IIECM'), findsWidgets);
    expect(find.text('IIECM Admin'), findsOneWidget);
    expect(find.text('Sign In as Administrator'), findsOneWidget);
    expect(find.text('Administrator Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}

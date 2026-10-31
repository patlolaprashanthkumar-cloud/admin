import 'package:flutter_test/flutter_test.dart';
import 'package:iiecm_admin/diagnostic_render_app.dart';

void main() {
  testWidgets('IIECMRenderDiagnosticApp renders and increments counter', (WidgetTester tester) async {
    await tester.pumpWidget(const IIECMRenderDiagnosticApp());

    // Verify initial rendering
    expect(find.text('IIECM FLUTTER RENDER TEST'), findsOneWidget);
    expect(find.text('Taps: 0'), findsOneWidget);

    // Tap increment button
    await tester.tap(find.text('Increment Counter'));
    await tester.pump();

    // Verify updated state
    expect(find.text('Taps: 1'), findsOneWidget);
  });
}


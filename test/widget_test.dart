// Smoke tests for the Decko product shell.

import 'package:flutter_test/flutter_test.dart';

import 'package:decko/app/decko_app.dart';
import 'package:decko/core/constants/decko_strings.dart';

void main() {
  testWidgets('Home shows Decko branding and entry points',
      (WidgetTester tester) async {
    await tester.pumpWidget(const DeckoApp());
    await tester.pumpAndSettle();

    expect(find.text(DeckoStrings.wordmark), findsOneWidget);
    expect(find.text(DeckoStrings.tagline), findsOneWidget);
    expect(find.text(DeckoStrings.importCta), findsOneWidget);
    expect(find.text(DeckoStrings.demoCta), findsOneWidget);
  });

  testWidgets('Demo CTA opens the review preview with a sample card',
      (WidgetTester tester) async {
    await tester.pumpWidget(const DeckoApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text(DeckoStrings.demoCta));
    await tester.pumpAndSettle();

    // The sample card front and the reveal action are present.
    expect(find.text('食べる'), findsOneWidget);
    expect(find.text('Show answer'), findsOneWidget);

    // Revealing exposes the four grading ratings.
    await tester.tap(find.text('Show answer'));
    await tester.pumpAndSettle();
    expect(find.text('Again'), findsOneWidget);
    expect(find.text('Easy'), findsOneWidget);
  });

  testWidgets('Theme gallery, import and progress screens open cleanly',
      (WidgetTester tester) async {
    await tester.pumpWidget(const DeckoApp());
    await tester.pumpAndSettle();

    // Theme gallery via the app-bar palette action.
    await tester.tap(find.byTooltip('Theme gallery'));
    await tester.pumpAndSettle();
    expect(find.text('App themes'), findsOneWidget);
    expect(find.text('Card themes'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    // Progress via the app-bar insights action.
    await tester.tap(find.byTooltip('Progress'));
    await tester.pumpAndSettle();
    expect(find.text('Achievements'), findsOneWidget);
    expect(find.text('First Review'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    // Import via the primary CTA.
    await tester.tap(find.text(DeckoStrings.importCta));
    await tester.pumpAndSettle();
    expect(find.text('Coming soon'), findsWidgets);
  });
}

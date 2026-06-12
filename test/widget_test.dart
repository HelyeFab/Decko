// Smoke tests for the Decko local demo deck flow.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:decko/app/decko_app.dart';
import 'package:decko/core/constants/decko_strings.dart';
import 'package:decko/domain/deck.dart';
import 'package:decko/domain/repositories/deck_repository.dart';

/// A repository with no decks, to exercise the empty-state fallback.
class _EmptyDeckRepository implements DeckRepository {
  const _EmptyDeckRepository();

  @override
  List<Deck> getDecks() => const <Deck>[];

  @override
  Deck? getDeckById(String id) => null;
}

/// Pumps the app on a tall phone-sized surface so screens lay out without the
/// vertical scrolling that would otherwise leave below-the-fold widgets unbuilt.
Future<void> _pumpApp(WidgetTester tester, {DeckRepository? repository}) async {
  tester.view.physicalSize = const Size(420, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    repository == null
        ? const DeckoApp()
        : DeckoApp(deckRepository: repository),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Home shows branding, a demo deck tile and entry points',
      (WidgetTester tester) async {
    await _pumpApp(tester);

    expect(find.text(DeckoStrings.wordmark), findsOneWidget);
    expect(find.text(DeckoStrings.tagline), findsOneWidget);
    expect(find.text('Japanese Starter Deck'), findsOneWidget);
    expect(find.text(DeckoStrings.importCta), findsOneWidget);
    expect(find.text(DeckoStrings.demoCta), findsOneWidget);
  });

  testWidgets('Tapping a deck tile opens deck detail',
      (WidgetTester tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Japanese Starter Deck'));
    await tester.pumpAndSettle();

    expect(find.text('Start review'), findsOneWidget);
    expect(find.text('Review modes coming soon'), findsOneWidget);
    // Sample items from the deck are listed.
    expect(find.text('食べる'), findsOneWidget);
  });

  testWidgets('Explore demo deck opens deck detail, then Start review opens '
      'the review preview', (WidgetTester tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text(DeckoStrings.demoCta));
    await tester.pumpAndSettle();
    expect(find.text('Start review'), findsOneWidget);

    await tester.tap(find.text('Start review'));
    await tester.pumpAndSettle();

    // Review preview shows the deck's first card and the reveal action.
    expect(find.text('Show answer'), findsOneWidget);
    await tester.tap(find.text('Show answer'));
    await tester.pumpAndSettle();
    expect(find.text('Again'), findsOneWidget);
    expect(find.text('Easy'), findsOneWidget);
  });

  testWidgets('Empty repository falls back to the empty-state card',
      (WidgetTester tester) async {
    await _pumpApp(tester, repository: const _EmptyDeckRepository());

    expect(find.text(DeckoStrings.emptyTitle), findsOneWidget);
    expect(find.text('Japanese Starter Deck'), findsNothing);
  });

  testWidgets('Theme gallery, import and progress screens open cleanly',
      (WidgetTester tester) async {
    await _pumpApp(tester);

    await tester.tap(find.byTooltip('Theme gallery'));
    await tester.pumpAndSettle();
    expect(find.text('App themes'), findsOneWidget);
    expect(find.text('Card themes'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Progress'));
    await tester.pumpAndSettle();
    expect(find.text('Achievements'), findsOneWidget);
    expect(find.text('First Review'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text(DeckoStrings.importCta));
    await tester.pumpAndSettle();
    expect(find.text('Coming soon'), findsWidgets);
  });
}

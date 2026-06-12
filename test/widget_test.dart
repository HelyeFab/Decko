// Smoke tests for the Decko deck flow and the review session loop.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:decko/app/decko_app.dart';
import 'package:decko/core/constants/decko_strings.dart';
import 'package:decko/domain/deck.dart';
import 'package:decko/domain/learning_item.dart';
import 'package:decko/domain/repositories/deck_repository.dart';

/// A repository with no decks, to exercise the empty-state fallback.
class _EmptyDeckRepository implements DeckRepository {
  const _EmptyDeckRepository();

  @override
  List<Deck> getDecks() => const <Deck>[];

  @override
  Deck? getDeckById(String id) => null;
}

/// A repository over a fixed list of decks (used for the empty-deck review case).
class _FixedDeckRepository implements DeckRepository {
  const _FixedDeckRepository(this.decks);

  final List<Deck> decks;

  @override
  List<Deck> getDecks() => decks;

  @override
  Deck? getDeckById(String id) {
    for (final Deck deck in decks) {
      if (deck.id == id) return deck;
    }
    return null;
  }
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

/// Home → Explore demo deck → Deck detail → Start review.
Future<void> _startReviewOfFirstDeck(WidgetTester tester) async {
  await tester.tap(find.text(DeckoStrings.demoCta));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Start review'));
  await tester.pumpAndSettle();
}

/// Reveals the current card and grades it with [rating].
Future<void> _answerCard(WidgetTester tester, String rating) async {
  await tester.tap(find.text('Show answer'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(rating));
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
    expect(find.text('食べる'), findsOneWidget);
  });

  testWidgets('Review loop: card 1 → grade → advance → completion summary → '
      'review again', (WidgetTester tester) async {
    await _pumpApp(tester);
    await _startReviewOfFirstDeck(tester);

    // Session starts on the first card of the 3-card demo deck.
    expect(find.text('Card 1 of 3'), findsOneWidget);
    expect(find.text('Show answer'), findsOneWidget);
    expect(find.text('Again'), findsNothing); // hidden before reveal

    // Reveal exposes the answer and the four ratings.
    await tester.tap(find.text('Show answer'));
    await tester.pumpAndSettle();
    expect(find.text('Again'), findsOneWidget);
    expect(find.text('Easy'), findsOneWidget);

    // Grading advances to the next card.
    await tester.tap(find.text('Good'));
    await tester.pumpAndSettle();
    expect(find.text('Card 2 of 3'), findsOneWidget);

    // Finish the remaining cards.
    await _answerCard(tester, 'Good');
    expect(find.text('Card 3 of 3'), findsOneWidget);
    await _answerCard(tester, 'Easy');

    // Completion summary.
    expect(find.text('Session complete'), findsOneWidget);
    expect(find.text('Cards reviewed: 3'), findsOneWidget);

    // Review again restarts at card 1.
    await tester.tap(find.text('Review again'));
    await tester.pumpAndSettle();
    expect(find.text('Card 1 of 3'), findsOneWidget);
  });

  testWidgets('Back to deck returns to deck detail',
      (WidgetTester tester) async {
    await _pumpApp(tester);
    await _startReviewOfFirstDeck(tester);

    await _answerCard(tester, 'Good');
    await _answerCard(tester, 'Good');
    await _answerCard(tester, 'Good');
    expect(find.text('Session complete'), findsOneWidget);

    await tester.tap(find.text('Back to deck'));
    await tester.pumpAndSettle();
    expect(find.text('Review modes coming soon'), findsOneWidget); // detail
  });

  testWidgets('Empty deck shows a graceful empty state, not a sample card',
      (WidgetTester tester) async {
    const Deck empty = Deck(
      id: 'empty',
      name: 'Empty Deck',
      description: 'No cards here yet.',
      items: <LearningItem>[],
    );
    await _pumpApp(tester, repository: const _FixedDeckRepository(<Deck>[empty]));

    await tester.tap(find.text('Empty Deck'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start review'));
    await tester.pumpAndSettle();

    expect(find.text('This deck has no cards yet.'), findsOneWidget);
    expect(find.text('Show answer'), findsNothing);
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

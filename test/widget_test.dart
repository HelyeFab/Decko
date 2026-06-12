// Smoke tests for the Decko deck flow, review loop, and local persistence.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:decko/app/decko_app.dart';
import 'package:decko/core/constants/decko_strings.dart';
import 'package:decko/data/mock_deck_repository.dart';
import 'package:decko/data/shared_prefs_progress_repository.dart';
import 'package:decko/data/shared_prefs_settings_repository.dart';
import 'package:decko/domain/deck.dart';
import 'package:decko/domain/learning_item.dart';
import 'package:decko/domain/progress_snapshot.dart';
import 'package:decko/domain/repositories/deck_repository.dart';
import 'package:decko/domain/repositories/progress_repository.dart';
import 'package:decko/domain/repositories/settings_repository.dart';
import 'package:decko/domain/review_session_result.dart';

class _EmptyDeckRepository implements DeckRepository {
  const _EmptyDeckRepository();
  @override
  List<Deck> getDecks() => const <Deck>[];
  @override
  Deck? getDeckById(String id) => null;
}

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

/// In-memory settings; writes land synchronously so two app pumps are
/// deterministic (no SharedPreferences timing).
class _InMemorySettings implements SettingsRepository {
  String? id;
  @override
  Future<String?> getSelectedAppThemeId() async => id;
  @override
  Future<void> saveSelectedAppThemeId(String themeId) async => id = themeId;
}

/// In-memory progress with an injectable clock; writes land synchronously.
class _InMemoryProgress implements ProgressRepository {
  _InMemoryProgress(this.now);
  final DateTime now;
  ProgressSnapshot snapshot = ProgressSnapshot.empty;
  @override
  Future<ProgressSnapshot> getSnapshot() async => snapshot;
  @override
  Future<void> recordSessionResult(ReviewSessionResult result) async =>
      snapshot = snapshot.recordingSession(result, now);
  @override
  Future<void> resetProgress() async => snapshot = ProgressSnapshot.empty;
}

Future<void> _pumpApp(
  WidgetTester tester, {
  DeckRepository? deckRepository,
  SettingsRepository? settingsRepository,
  ProgressRepository? progressRepository,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  tester.view.physicalSize = const Size(420, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    DeckoApp(
      deckRepository: deckRepository ?? const MockDeckRepository(),
      settingsRepository:
          settingsRepository ?? const SharedPrefsSettingsRepository(),
      progressRepository:
          progressRepository ?? const SharedPrefsProgressRepository(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _startReviewOfFirstDeck(WidgetTester tester) async {
  await tester.tap(find.text(DeckoStrings.demoCta));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Start review'));
  await tester.pumpAndSettle();
}

Future<void> _answerCard(WidgetTester tester, String rating) async {
  await tester.tap(find.text('Show answer'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(rating));
  await tester.pumpAndSettle();
}

Brightness _appBrightness(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!.brightness;

void main() {
  testWidgets('Home shows branding, a demo deck tile and entry points',
      (WidgetTester tester) async {
    await _pumpApp(tester);
    expect(find.text(DeckoStrings.wordmark), findsOneWidget);
    expect(find.text('Japanese Starter Deck'), findsOneWidget);
    expect(find.text(DeckoStrings.importCta), findsOneWidget);
  });

  testWidgets('Review loop records progress shown on the Progress screen',
      (WidgetTester tester) async {
    final _InMemoryProgress progress =
        _InMemoryProgress(DateTime(2026, 6, 12, 10));
    await _pumpApp(tester, progressRepository: progress);

    await _startReviewOfFirstDeck(tester);
    expect(find.text('Card 1 of 3'), findsOneWidget);
    await _answerCard(tester, 'Good');
    await _answerCard(tester, 'Good');
    await _answerCard(tester, 'Good');
    expect(find.text('Session complete'), findsOneWidget);

    // Progress was recorded: 3 cards * 10 XP.
    expect(progress.snapshot.totalXp, 30);
    expect(progress.snapshot.cardsReviewedToday, 3);

    // Back to deck → home → Progress reflects it.
    await tester.tap(find.text('Back to deck'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Progress'));
    await tester.pumpAndSettle();

    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('30 XP earned'), findsOneWidget);
    expect(find.text('Your latest review'), findsOneWidget);
  });

  testWidgets('Progress screen shows a warm empty state before any session',
      (WidgetTester tester) async {
    await _pumpApp(tester);
    await tester.tap(find.byTooltip('Progress'));
    await tester.pumpAndSettle();

    expect(find.text('No progress yet'), findsOneWidget);
    expect(find.textContaining('Complete your first review session'),
        findsOneWidget);
    expect(find.text('Your latest review'), findsNothing);
  });

  testWidgets('Selected app theme persists across a restart',
      (WidgetTester tester) async {
    final _InMemorySettings settings = _InMemorySettings();
    await _pumpApp(tester, settingsRepository: settings);

    // Default is the light "Soft Study" theme.
    expect(_appBrightness(tester), Brightness.light);

    await tester.tap(find.byTooltip('Theme gallery'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Decko Dark'));
    await tester.pumpAndSettle();
    expect(_appBrightness(tester), Brightness.dark);
    expect(settings.id, 'decko-dark');

    // "Restart": a fresh app sharing the same settings store hydrates dark.
    await tester.pumpWidget(DeckoApp(settingsRepository: settings));
    await tester.pumpAndSettle();
    expect(_appBrightness(tester), Brightness.dark);
  });

  testWidgets('Empty deck shows a graceful empty state, not a sample card',
      (WidgetTester tester) async {
    const Deck empty = Deck(
      id: 'empty',
      name: 'Empty Deck',
      description: 'No cards here yet.',
      items: <LearningItem>[],
    );
    await _pumpApp(tester,
        deckRepository: const _FixedDeckRepository(<Deck>[empty]));

    await tester.tap(find.text('Empty Deck'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start review'));
    await tester.pumpAndSettle();

    expect(find.text('This deck has no cards yet.'), findsOneWidget);
    expect(find.text('Show answer'), findsNothing);
  });

  testWidgets('Empty repository falls back to the empty-state card',
      (WidgetTester tester) async {
    await _pumpApp(tester, deckRepository: const _EmptyDeckRepository());
    expect(find.text(DeckoStrings.emptyTitle), findsOneWidget);
    expect(find.text('Japanese Starter Deck'), findsNothing);
  });

  testWidgets('Theme gallery and import screens open cleanly',
      (WidgetTester tester) async {
    await _pumpApp(tester);

    await tester.tap(find.byTooltip('Theme gallery'));
    await tester.pumpAndSettle();
    expect(find.text('App themes'), findsOneWidget);
    expect(find.text('Card themes'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text(DeckoStrings.importCta));
    await tester.pumpAndSettle();
    expect(find.text('Coming soon'), findsWidgets);
  });
}

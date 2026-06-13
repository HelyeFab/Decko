// Smoke tests for the Decko deck flow, review loop, and local persistence.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:decko/app/decko_app.dart';
import 'package:decko/core/constants/decko_strings.dart';
import 'package:decko/data/imported_deck_storage.dart';
import 'package:decko/data/mock_deck_repository.dart';
import 'package:decko/data/shared_prefs_progress_repository.dart';
import 'package:decko/data/shared_prefs_review_state_repository.dart';
import 'package:decko/data/shared_prefs_settings_repository.dart';
import 'package:decko/domain/deck.dart';
import 'package:decko/domain/learning_item.dart';
import 'package:decko/domain/progress_snapshot.dart';
import 'package:decko/domain/repositories/deck_repository.dart';
import 'package:decko/domain/repositories/progress_repository.dart';
import 'package:decko/domain/import/deck_import_info.dart';
import 'package:decko/domain/import/deck_import_preview.dart';
import 'dart:typed_data';

import 'package:decko/domain/repositories/media_store.dart';
import 'package:decko/domain/repositories/review_state_repository.dart';
import 'package:decko/domain/repositories/settings_repository.dart';
import 'package:decko/domain/review_card_state.dart';
import 'package:decko/app/theme/card_theme_config.dart';
import 'package:decko/core/widgets/decko_card.dart';
import 'package:decko/domain/review_session_result.dart';
import 'package:decko/features/import/widgets/import_preview_panel.dart';

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
  bool furigana = true;
  @override
  Future<String?> getSelectedAppThemeId() async => id;
  @override
  Future<void> saveSelectedAppThemeId(String themeId) async => id = themeId;
  @override
  Future<bool> getShowFurigana() async => furigana;
  @override
  Future<void> saveShowFurigana(bool show) async => furigana = show;
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

/// In-memory review state, seedable and synchronous-ish for deterministic tests.
class _InMemoryReviewState implements ReviewStateRepository {
  final Map<String, List<ReviewCardState>> _byDeck =
      <String, List<ReviewCardState>>{};

  void seed(List<ReviewCardState> states) {
    if (states.isEmpty) return;
    _byDeck[states.first.deckId] = List<ReviewCardState>.from(states);
  }

  @override
  Future<List<ReviewCardState>> getStatesForDeck(String deckId) async =>
      _byDeck[deckId] ?? const <ReviewCardState>[];
  @override
  Future<ReviewCardState?> getState(String deckId, String itemId) async {
    for (final ReviewCardState s in _byDeck[deckId] ?? const <ReviewCardState>[]) {
      if (s.itemId == itemId) return s;
    }
    return null;
  }

  @override
  Future<void> saveState(ReviewCardState state) async =>
      saveStates(<ReviewCardState>[state]);
  @override
  Future<void> saveStates(List<ReviewCardState> states) async {
    if (states.isEmpty) return;
    final Map<String, ReviewCardState> merged = <String, ReviewCardState>{
      for (final ReviewCardState s in _byDeck[states.first.deckId] ??
          const <ReviewCardState>[])
        s.itemId: s,
      for (final ReviewCardState s in states) s.itemId: s,
    };
    _byDeck[states.first.deckId] = merged.values.toList();
  }

  @override
  Future<void> resetDeckStates(String deckId) async => _byDeck.remove(deckId);
}

/// In-memory media store so widget tests avoid path_provider.
class _InMemoryMediaStore implements MediaStore {
  final Map<String, Uint8List> _files = <String, Uint8List>{};
  @override
  Future<void> saveMedia(String deckId, String fileName, Uint8List bytes) async =>
      _files['$deckId/$fileName'] = bytes;
  @override
  Future<String?> resolveMedia(String deckId, String fileName) async =>
      _files.containsKey('$deckId/$fileName') ? '$deckId/$fileName' : null;
  @override
  Future<void> deleteMediaForDeck(String deckId) async =>
      _files.removeWhere((String k, _) => k.startsWith('$deckId/'));
}

Future<void> _pumpApp(
  WidgetTester tester, {
  DeckRepository? deckRepository,
  SettingsRepository? settingsRepository,
  ProgressRepository? progressRepository,
  ReviewStateRepository? reviewStateRepository,
  MediaStore? mediaStore,
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
      reviewStateRepository:
          reviewStateRepository ?? const SharedPrefsReviewStateRepository(),
      mediaStore: mediaStore ?? _InMemoryMediaStore(),
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
    expect(find.text('Import Anki deck (.apkg)'), findsOneWidget);
    expect(find.text('Coming soon'), findsWidgets); // CSV/JSON still placeholder
  });

  testWidgets('Import preview offers keep/start-fresh when progress exists',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ImportPreviewPanel(
          preview: const DeckImportPreview(
            deckName: 'Japanese Core',
            totalCards: 100,
            newCards: 60,
            reviewedCards: 40,
            suspendedCards: 3,
            hasProgressData: true,
          ),
          onKeepProgress: () {},
          onStartFresh: () {},
          onCancel: () {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Japanese Core'), findsOneWidget);
    expect(find.text('Cards found'), findsOneWidget);
    expect(find.text('Keep Anki progress'), findsOneWidget);
    expect(find.text('Start fresh'), findsOneWidget);
  });

  testWidgets('Import preview warns honestly when no progress is found',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ImportPreviewPanel(
          preview: const DeckImportPreview(
            deckName: 'Vocab',
            totalCards: 20,
            newCards: 20,
            reviewedCards: 0,
            suspendedCards: 0,
            hasProgressData: false,
          ),
          onKeepProgress: () {},
          onStartFresh: () {},
          onCancel: () {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Keep Anki progress'), findsNothing);
    expect(find.textContaining('they will start as new'), findsOneWidget);
    expect(find.text('Import as new'), findsOneWidget);
  });

  testWidgets('Imported deck detail shows Due today / Reviewed from review state',
      (WidgetTester tester) async {
    final DateTime overdue = DateTime(2020, 1, 1);
    final Deck deck = Deck(
      id: 'anki-x',
      name: 'Imported',
      description: 'desc',
      importInfo: DeckImportInfo(
          progressMode: ImportProgressMode.kept, importedAt: DateTime(2026)),
      items: const <LearningItem>[
        LearningItem(id: 'a', front: 'a', back: 'a'),
        LearningItem(id: 'b', front: 'b', back: 'b'),
        LearningItem(id: 'c', front: 'c', back: 'c'),
      ],
    );

    final _InMemoryReviewState states = _InMemoryReviewState()
      ..seed(<ReviewCardState>[
        ReviewCardState(
            deckId: 'anki-x',
            itemId: 'a',
            queueState: ReviewQueueState.review,
            reps: 3,
            dueAt: overdue),
        ReviewCardState(
            deckId: 'anki-x',
            itemId: 'b',
            queueState: ReviewQueueState.review,
            reps: 1,
            dueAt: overdue),
        ReviewCardState.newCard(deckId: 'anki-x', itemId: 'c'),
      ]);

    await _pumpApp(tester,
        deckRepository: _FixedDeckRepository(<Deck>[deck]),
        reviewStateRepository: states);

    await tester.tap(find.text('Imported'));
    await tester.pumpAndSettle();

    // Two review cards due/reviewed; total 3.
    expect(find.text('3'), findsOneWidget); // total cards
    expect(find.text('2'), findsNWidgets(2)); // due today + reviewed
    expect(find.text('Progress: kept from Anki'), findsOneWidget);
  });

  testWidgets('Due today decrements after reviewing due cards',
      (WidgetTester tester) async {
    final DateTime overdue = DateTime(2020, 1, 1);
    final Deck deck = Deck(
      id: 'd1',
      name: 'My Deck',
      description: 'desc',
      items: const <LearningItem>[
        LearningItem(id: 'a', front: 'a', back: 'a'),
        LearningItem(id: 'b', front: 'b', back: 'b'),
      ],
    );
    final _InMemoryReviewState states = _InMemoryReviewState()
      ..seed(<ReviewCardState>[
        ReviewCardState(
            deckId: 'd1',
            itemId: 'a',
            queueState: ReviewQueueState.review,
            reps: 1,
            dueAt: overdue),
        ReviewCardState(
            deckId: 'd1',
            itemId: 'b',
            queueState: ReviewQueueState.review,
            reps: 1,
            dueAt: overdue),
      ]);

    await _pumpApp(tester,
        deckRepository: _FixedDeckRepository(<Deck>[deck]),
        reviewStateRepository: states);

    await tester.tap(find.text('My Deck'));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsNWidgets(3)); // total + due + reviewed all 2

    await tester.tap(find.text('Start review'));
    await tester.pumpAndSettle();
    expect(find.text('Card 1 of 2'), findsOneWidget);
    await _answerCard(tester, 'Good');
    await _answerCard(tester, 'Good');
    expect(find.text('Session complete'), findsOneWidget);

    await tester.tap(find.text('Back to deck'));
    await tester.pumpAndSettle();

    // Both cards pushed to the future → due today is now 0; reviewed still 2.
    expect(find.text('0'), findsOneWidget); // due today
    expect(find.text('2'), findsNWidgets(2)); // total + reviewed
  });

  testWidgets('Stopping mid-session (app-bar back) still updates Due today',
      (WidgetTester tester) async {
    final DateTime overdue = DateTime(2020, 1, 1);
    final Deck deck = Deck(
      id: 'd4',
      name: 'Mid Deck',
      description: 'desc',
      items: const <LearningItem>[
        LearningItem(id: 'a', front: 'a', back: 'a'),
        LearningItem(id: 'b', front: 'b', back: 'b'),
      ],
    );
    final _InMemoryReviewState states = _InMemoryReviewState()
      ..seed(<ReviewCardState>[
        ReviewCardState(
            deckId: 'd4',
            itemId: 'a',
            queueState: ReviewQueueState.review,
            reps: 1,
            dueAt: overdue),
        ReviewCardState(
            deckId: 'd4',
            itemId: 'b',
            queueState: ReviewQueueState.review,
            reps: 1,
            dueAt: overdue),
      ]);

    await _pumpApp(tester,
        deckRepository: _FixedDeckRepository(<Deck>[deck]),
        reviewStateRepository: states);

    await tester.tap(find.text('Mid Deck'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start review'));
    await tester.pumpAndSettle();

    // Grade just one of the two due cards, then leave via the app-bar back.
    await _answerCard(tester, 'Good');
    expect(find.text('Card 2 of 2'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // One card pushed to the future → due today is now 1 (not stale 2).
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('Revealed card shows the example in a labelled box',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: DeckoCard(
          item: LearningItem(
            id: 'x',
            front: '食[た]べる',
            back: 'to eat',
            example: '毎日食べます。\nI eat every day.',
          ),
          deckId: 'd',
          style: CardThemeStyle.minimal,
          revealed: true,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('to eat'), findsOneWidget); // meaning
    expect(find.text('EXAMPLE'), findsOneWidget); // separated, labelled box
    expect(find.text('I eat every day.'), findsOneWidget); // translation
  });

  testWidgets('Swipe-left deletes an imported deck after confirmation',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final Deck imported = Deck(
      id: 'anki-z',
      name: 'Imported Z',
      description: 'd',
      importInfo: DeckImportInfo(
          progressMode: ImportProgressMode.fresh, importedAt: DateTime(2026)),
      items: const <LearningItem>[LearningItem(id: 'a', front: 'a', back: 'a')],
    );
    await const ImportedDeckStorage().save(<Deck>[imported]);

    await tester.pumpWidget(DeckoApp(mediaStore: _InMemoryMediaStore()));
    await tester.pumpAndSettle();
    expect(find.text('Imported Z'), findsOneWidget);

    // Swipe the imported deck tile left, then confirm.
    await tester.fling(find.text('Imported Z'), const Offset(-600, 0), 1200);
    await tester.pumpAndSettle();
    expect(find.text('Delete deck'), findsOneWidget); // custom confirm dialog
    await tester.tap(find.text('Delete deck'));
    await tester.pumpAndSettle();

    expect(find.text('Imported Z'), findsNothing);
    // Demo decks remain.
    expect(find.text('Japanese Starter Deck'), findsOneWidget);
  });

  testWidgets('Empty due queue shows the all-caught-up state',
      (WidgetTester tester) async {
    final Deck deck = Deck(
      id: 'd2',
      name: 'Future Deck',
      description: 'desc',
      items: const <LearningItem>[LearningItem(id: 'a', front: 'a', back: 'a')],
    );
    final _InMemoryReviewState states = _InMemoryReviewState()
      ..seed(<ReviewCardState>[
        ReviewCardState(
            deckId: 'd2',
            itemId: 'a',
            queueState: ReviewQueueState.review,
            reps: 1,
            dueAt: DateTime(2030)), // far future → not due
      ]);

    await _pumpApp(tester,
        deckRepository: _FixedDeckRepository(<Deck>[deck]),
        reviewStateRepository: states);

    await tester.tap(find.text('Future Deck'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start review'));
    await tester.pumpAndSettle();

    expect(find.text('All caught up.'), findsOneWidget);
    expect(find.text('Show answer'), findsNothing);
  });

  testWidgets('Suspended cards are excluded from the due queue',
      (WidgetTester tester) async {
    final Deck deck = Deck(
      id: 'd3',
      name: 'Mixed Deck',
      description: 'desc',
      items: const <LearningItem>[
        LearningItem(id: 'a', front: 'a', back: 'a'),
        LearningItem(id: 'b', front: 'b', back: 'b'),
      ],
    );
    final _InMemoryReviewState states = _InMemoryReviewState()
      ..seed(<ReviewCardState>[
        ReviewCardState(
            deckId: 'd3',
            itemId: 'a',
            queueState: ReviewQueueState.suspended),
        ReviewCardState(
            deckId: 'd3',
            itemId: 'b',
            queueState: ReviewQueueState.review,
            reps: 1,
            dueAt: DateTime(2020)),
      ]);

    await _pumpApp(tester,
        deckRepository: _FixedDeckRepository(<Deck>[deck]),
        reviewStateRepository: states);

    await tester.tap(find.text('Mixed Deck'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start review'));
    await tester.pumpAndSettle();

    // Only the non-suspended due card is in the queue.
    expect(find.text('Card 1 of 1'), findsOneWidget);
  });
}

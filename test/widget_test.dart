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
import 'package:decko/domain/import/import_diagnostics.dart';
import 'dart:typed_data';

import 'package:decko/domain/import/source/imported_anki_source.dart';
import 'package:decko/domain/repositories/imported_source_store.dart';
import 'package:decko/domain/repositories/media_store.dart';
import 'package:decko/domain/repositories/daily_study_counts_repository.dart';
import 'package:decko/domain/repositories/study_options_repository.dart';
import 'package:decko/domain/study_options/daily_study_counts.dart';
import 'package:decko/domain/study_options/study_options.dart';
import 'package:decko/domain/repositories/review_state_repository.dart';
import 'package:decko/domain/repositories/settings_repository.dart';
import 'package:decko/domain/review_card_state.dart';
import 'package:decko/app/theme/card_theme_config.dart';
import 'package:decko/core/widgets/decko_card.dart';
import 'package:decko/domain/review_card_mode.dart';
import 'package:decko/domain/review_session_result.dart';
import 'package:decko/features/import/widgets/import_preview_panel.dart';
import 'package:decko/features/import/widgets/import_health_summary.dart';
import 'package:decko/features/review/widgets/session_summary.dart';
import 'package:decko/features/sentence_builder/sentence_builder_screen.dart';
import 'package:decko/domain/sentence_builder/sentence_builder_round.dart';
import 'package:decko/domain/sentence_builder/sentence_builder_source.dart';
import 'package:decko/domain/sentence_builder/sentence_builder_token.dart';
import 'package:decko/domain/sentence_builder/cube_token.dart';
import 'package:decko/domain/sentence_builder/sentence_tokenizer.dart';
import 'package:decko/domain/repositories/sentence_token_cache.dart';
import 'package:decko/domain/practice/practice_outcome.dart';
import 'package:decko/domain/activity/activity_event.dart';
import 'package:decko/domain/repositories/activity_ledger_repository.dart';
import 'package:decko/features/deck_library/widgets/study_ribbon.dart';

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

/// In-memory activity ledger so tests avoid path_provider.
class _InMemoryLedger implements ActivityLedgerRepository {
  final List<ActivityEvent> events = <ActivityEvent>[];
  void seed(List<ActivityEvent> e) => events.addAll(e);
  @override
  Future<void> record(ActivityEvent event) async => events.add(event);
  @override
  Future<List<ActivityEvent>> allEvents() async =>
      List<ActivityEvent>.of(events);
  @override
  Future<List<ActivityEvent>> eventsBetween(
          DateTime start, DateTime end) async =>
      events
          .where((ActivityEvent e) =>
              !e.occurredAt.isBefore(start) && e.occurredAt.isBefore(end))
          .toList();
  @override
  Future<List<ActivityEvent>> recentEvents({int limit = 50}) async =>
      (List<ActivityEvent>.of(events)
            ..sort((ActivityEvent a, ActivityEvent b) =>
                b.occurredAt.compareTo(a.occurredAt)))
          .take(limit)
          .toList();
}

/// A fake tokenizer that splits each line on spaces — deterministic, offline.
class _SplitTokenizer implements SentenceTokenizer {
  @override
  Future<TokenizeResult> tokenize(List<String> lines) async => TokenizeResult(
        lines: lines,
        tokens: <List<CubeToken>>[
          for (final String l in lines)
            <CubeToken>[
              for (final String w
                  in l.split(' ').where((String w) => w.isNotEmpty))
                CubeToken(surface: w),
            ],
        ],
      );
}

class _InMemoryTokenCache implements SentenceTokenCache {
  final Map<String, Map<String, CachedTokenization>> _byDeck =
      <String, Map<String, CachedTokenization>>{};
  @override
  Future<Map<String, CachedTokenization>> load(String deckId) async =>
      Map<String, CachedTokenization>.of(
          _byDeck[deckId] ?? const <String, CachedTokenization>{});
  @override
  Future<void> save(
          String deckId, Map<String, CachedTokenization> entries) async =>
      (_byDeck[deckId] ??= <String, CachedTokenization>{}).addAll(entries);
  @override
  Future<void> clear(String deckId) async => _byDeck.remove(deckId);
}

/// In-memory settings; writes land synchronously so two app pumps are
/// deterministic (no SharedPreferences timing).
class _InMemorySettings implements SettingsRepository {
  String? id;
  bool furigana = true;
  int dailyGoal = 20;
  @override
  Future<String?> getSelectedAppThemeId() async => id;
  @override
  Future<void> saveSelectedAppThemeId(String themeId) async => id = themeId;
  @override
  Future<bool> getShowFurigana() async => furigana;
  @override
  Future<void> saveShowFurigana(bool show) async => furigana = show;
  @override
  Future<int> getDailyGoal() async => dailyGoal;
  @override
  Future<void> saveDailyGoal(int goal) async => dailyGoal = goal;
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
  Future<void> recordPracticeOutcome(PracticeOutcome outcome) async =>
      snapshot = snapshot.recordingPractice(outcome.xpAwarded);
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

class _InMemorySourceStore implements ImportedSourceStore {
  final Map<String, ImportedAnkiSource> _byDeck = <String, ImportedAnkiSource>{};
  void seed(ImportedAnkiSource source) => _byDeck[source.deckId] = source;
  @override
  Future<void> saveSource(ImportedAnkiSource source) async =>
      _byDeck[source.deckId] = source;
  @override
  Future<ImportedAnkiSource?> getSourceForDeck(String deckId) async =>
      _byDeck[deckId];
  @override
  Future<void> deleteSourceForDeck(String deckId) async =>
      _byDeck.remove(deckId);
}

class _InMemoryStudyOptionsRepository implements StudyOptionsRepository {
  StudyOptions global = StudyOptions.defaults;
  final Map<String, DeckStudyOptions> deckOptions = <String, DeckStudyOptions>{};
  final List<StudyOptionProfile> profiles = <StudyOptionProfile>[];

  StudyOptionProfile get _default => StudyOptionProfile(
      id: StudyOptionProfile.defaultId,
      name: 'Default',
      options: global,
      isDefault: true);

  @override
  Future<StudyOptions> getGlobalOptions() async => global;
  @override
  Future<void> saveGlobalOptions(StudyOptions options) async => global = options;

  @override
  Future<List<StudyOptionProfile>> listProfiles() async =>
      <StudyOptionProfile>[_default, ...profiles];
  @override
  Future<StudyOptionProfile?> getProfile(String id) async {
    if (id == StudyOptionProfile.defaultId) return _default;
    for (final StudyOptionProfile p in profiles) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Future<void> saveProfile(StudyOptionProfile profile) async {
    if (profile.isDefault) return;
    final int i = profiles.indexWhere((StudyOptionProfile p) => p.id == profile.id);
    if (i >= 0) {
      profiles[i] = profile;
    } else {
      profiles.add(profile);
    }
  }

  @override
  Future<void> deleteProfile(String id) async =>
      profiles.removeWhere((StudyOptionProfile p) => p.id == id);

  @override
  Future<DeckStudyOptions?> getDeckOptions(String deckId) async =>
      deckOptions[deckId];
  @override
  Future<void> saveDeckOptions(String deckId, DeckStudyOptions options) async =>
      deckOptions[deckId] = options;
  @override
  Future<void> deleteDeckOptions(String deckId) async =>
      deckOptions.remove(deckId);

  @override
  Future<EffectiveStudyOptions> getEffectiveOptions(String deckId) async {
    final DeckStudyOptions? deck = deckOptions[deckId];
    StudyOptions base = global;
    final String? pid = deck?.profileId;
    if (pid != null && pid != StudyOptionProfile.defaultId) {
      final StudyOptionProfile? p = await getProfile(pid);
      if (p != null) base = p.options;
    }
    return EffectiveStudyOptions.resolve(base, deck);
  }
}

class _InMemoryDailyCountsRepository implements DailyStudyCountsRepository {
  final Map<String, DailyStudyCounts> _byDeck = <String, DailyStudyCounts>{};
  void seed(String deckId, DailyStudyCounts counts) =>
      _byDeck[deckId] = counts;
  @override
  Future<DailyStudyCounts> getCounts(String deckId, DateTime today) async =>
      (_byDeck[deckId] ?? DailyStudyCounts.empty(today)).forDay(today);
  @override
  Future<void> saveCounts(String deckId, DailyStudyCounts counts) async =>
      _byDeck[deckId] = counts;
}

Future<void> _pumpApp(
  WidgetTester tester, {
  DeckRepository? deckRepository,
  SettingsRepository? settingsRepository,
  ProgressRepository? progressRepository,
  ReviewStateRepository? reviewStateRepository,
  MediaStore? mediaStore,
  ImportedSourceStore? importedSourceStore,
  StudyOptionsRepository? studyOptionsRepository,
  DailyStudyCountsRepository? dailyStudyCountsRepository,
  ActivityLedgerRepository? activityLedger,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  // Sentence builder uses a fake tokenizer + in-memory cache (no network).
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
      importedSourceStore: importedSourceStore ?? _InMemorySourceStore(),
      studyOptionsRepository:
          studyOptionsRepository ?? _InMemoryStudyOptionsRepository(),
      dailyStudyCountsRepository:
          dailyStudyCountsRepository ?? _InMemoryDailyCountsRepository(),
      tokenizer: _SplitTokenizer(),
      sentenceTokenCache: _InMemoryTokenCache(),
      activityLedger: activityLedger ?? _InMemoryLedger(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _startReviewOfFirstDeck(WidgetTester tester) async {
  // Open the deck via its shelf row (the ribbon also shows the name), then
  // start the session from deck detail.
  await tester.tap(find.text('Japanese Starter Deck').last);
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
    // The deck name appears in the study ribbon and its shelf row.
    expect(find.text('Japanese Starter Deck'), findsWidgets);
    expect(find.text(DeckoStrings.importCta), findsOneWidget);
  });

  testWidgets('Home leads with the study ribbon, not the marketing grid',
      (WidgetTester tester) async {
    await _pumpApp(tester);
    expect(find.text('CONTINUE STUDYING'), findsOneWidget); // ribbon hero
    expect(find.text('Your decks'), findsOneWidget);
    // The product promise grid is no longer crowding a populated Home.
    expect(find.text('Why you’ll love Decko'), findsNothing);
  });

  testWidgets('Multiple decks render a swipeable study rolodex',
      (WidgetTester tester) async {
    const _FixedDeckRepository repo = _FixedDeckRepository(<Deck>[
      Deck(
          id: 'd1',
          name: 'Alpha Deck',
          description: 'd',
          items: <LearningItem>[LearningItem(id: 'a', front: 'a', back: 'a')]),
      Deck(
          id: 'd2',
          name: 'Beta Deck',
          description: 'd',
          items: <LearningItem>[LearningItem(id: 'b', front: 'b', back: 'b')]),
    ]);
    await _pumpApp(tester, deckRepository: repo);

    // One persistent header over a vertical-flip rolodex of deck cards.
    expect(find.text('CONTINUE STUDYING'), findsOneWidget);
    expect(find.byType(StudyRolodex), findsOneWidget);

    // Flipping the rolodex vertically (drag up) doesn't throw.
    await tester.drag(find.byType(StudyRolodex), const Offset(0, -220));
    await tester.pumpAndSettle();
    expect(find.byType(StudyRolodex), findsOneWidget);
  });

  testWidgets('Empty Home keeps the inviting promise grid',
      (WidgetTester tester) async {
    await _pumpApp(tester, deckRepository: const _EmptyDeckRepository());
    expect(find.text(DeckoStrings.emptyTitle), findsOneWidget);
    expect(find.text('Why you’ll love Decko'), findsOneWidget);
  });

  testWidgets('Import action on Home opens the Import screen',
      (WidgetTester tester) async {
    await _pumpApp(tester);
    await tester.tap(find.text(DeckoStrings.importCta));
    await tester.pumpAndSettle();
    expect(find.text('Import Anki deck (.apkg)'), findsOneWidget);
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
    expect(find.text('Recent activity'), findsOneWidget);
    expect(find.text('Reviewed 3 cards'), findsOneWidget);
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
    // The daily goal + achievements still appear, as motivation (MVP_015).
    expect(find.textContaining('of 20 cards reviewed'), findsOneWidget);
    expect(find.text('Achievements'), findsOneWidget);
  });

  testWidgets('Progress derives a met daily goal + streak from the ledger '
      '(MVP_019)', (WidgetTester tester) async {
    final _InMemoryLedger ledger = _InMemoryLedger();
    final DateTime now = DateTime.now();
    ActivityEvent rev(DateTime when, int cards) => ActivityEvent(
          id: 'e${when.microsecondsSinceEpoch}',
          occurredAt: when,
          source: ActivitySource.review,
          modeId: ActivityModeIds.standardReview,
          outcome: ActivityOutcome.completed,
          xpAwarded: cards * 10,
          metadata: <String, Object?>{'reviewedCards': cards},
        );
    // Three consecutive days → a 3-day streak; 20 cards today → goal met.
    ledger.seed(<ActivityEvent>[
      rev(now, 20),
      rev(now.subtract(const Duration(days: 1)), 10),
      rev(now.subtract(const Duration(days: 2)), 10),
    ]);

    await _pumpApp(tester,
        deckRepository: const _EmptyDeckRepository(), activityLedger: ledger);
    await tester.tap(find.byTooltip('Progress'));
    await tester.pumpAndSettle();

    expect(find.text('Daily goal reached!'), findsOneWidget); // 20 of 20
    expect(find.text('Achievements'), findsOneWidget);
    expect(find.text('First review'), findsOneWidget); // achievement badge
    expect(find.text('3-day streak'), findsOneWidget);
  });

  testWidgets('Session summary celebrates with reward chips (MVP_015)',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SessionSummary(
          result: const ReviewSessionResult(
            deckId: 'd',
            totalCards: 5,
            againCount: 0,
            hardCount: 1,
            goodCount: 3,
            easyCount: 1,
          ),
          onBackToDeck: () {},
          onReviewAgain: () {},
          xpGained: 50,
          streakDays: 3,
          dailyReviewed: 20,
          dailyGoal: 20,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Session complete'), findsOneWidget);
    expect(find.text('+50 XP'), findsOneWidget);
    expect(find.text('3 day streak'), findsOneWidget);
    expect(find.text('Daily goal reached'), findsOneWidget);
  });

  // ---- MVP_016: Sentence Builder ------------------------------------------

  Deck sentenceDeck() => Deck(
        id: 'sb',
        name: 'Sentence Deck',
        description: 'd',
        importInfo: DeckImportInfo(
          progressMode: ImportProgressMode.fresh,
          importedAt: DateTime(2026),
        ),
        items: const <LearningItem>[
          LearningItem(
              id: 'sb1', front: 'go', back: 'went', example: 'one two three'),
        ],
      );

  testWidgets('Sentence builder plays a round to completion (MVP_016)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const SentenceBuilderRound round = SentenceBuilderRound(
      deckId: 'd',
      source: SentenceBuilderSource.deckPractice,
      sentence: 'one two three',
      tokens: <SentenceBuilderToken>[
        SentenceBuilderToken(text: 'one', position: 0),
        SentenceBuilderToken(text: 'two', position: 1),
        SentenceBuilderToken(text: 'three', position: 2),
      ],
    );

    await tester.pumpWidget(const MaterialApp(
      home: SentenceBuilderScreen(rounds: <SentenceBuilderRound>[round]),
    ));
    await tester.pumpAndSettle();

    // Build in the correct order; each word is only in the bank when tapped.
    for (final String word in <String>['one', 'two', 'three']) {
      await tester.tap(find.text(word));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    expect(find.text('Perfect!'), findsOneWidget);

    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();
    expect(find.text('Practice complete'), findsOneWidget);
    expect(find.textContaining('review schedule is unchanged'), findsOneWidget);
  });

  testWidgets('Manual "Build this sentence" shows on a sentence card (MVP_016)',
      (WidgetTester tester) async {
    await _pumpApp(tester,
        deckRepository: _FixedDeckRepository(<Deck>[sentenceDeck()]));

    await tester.tap(find.text('Sentence Deck').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show answer'));
    await tester.pumpAndSettle();

    expect(find.text('Build this sentence'), findsOneWidget);
  });

  testWidgets(
      'Sentence-builder review presentation grades through the normal seam (MVP_016)',
      (WidgetTester tester) async {
    final _InMemoryStudyOptionsRepository options =
        _InMemoryStudyOptionsRepository()
          ..global = const StudyOptions(sentenceBuilderReview: true);
    final _InMemoryProgress progress =
        _InMemoryProgress(DateTime(2026, 6, 21, 10));

    await _pumpApp(tester,
        deckRepository: _FixedDeckRepository(<Deck>[sentenceDeck()]),
        studyOptionsRepository: options,
        progressRepository: progress);

    await tester.tap(find.text('Sentence Deck').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start review'));
    await tester.pumpAndSettle();

    // The card is presented as a builder, not the normal flashcard.
    expect(find.text('Tap the words below in order'), findsOneWidget);
    expect(find.text('Check'), findsOneWidget);

    for (final String word in <String>['one', 'two', 'three']) {
      await tester.tap(find.text(word));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();

    // Resolving reveals the normal grade buttons; grading flows as usual.
    expect(find.text('How well did you know it?'), findsOneWidget);
    await tester.tap(find.text('Good'));
    await tester.pumpAndSettle();

    expect(find.text('Session complete'), findsOneWidget);
    // The grade went through the normal review-answer seam (progress recorded).
    expect(progress.snapshot.cardsReviewedToday, 1);
    expect(progress.snapshot.totalXp, 10);
  });

  testWidgets(
      'Manual practice records motivation XP but never review state (MVP_017)',
      (WidgetTester tester) async {
    final _InMemoryProgress progress =
        _InMemoryProgress(DateTime(2026, 6, 22, 10));
    await _pumpApp(tester,
        deckRepository: _FixedDeckRepository(<Deck>[sentenceDeck()]),
        progressRepository: progress);

    await tester.tap(find.text('Sentence Deck').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show answer'));
    await tester.pumpAndSettle();

    // Launch manual practice from the card and play it to completion.
    await tester.tap(find.text('Build this sentence'));
    await tester.pumpAndSettle();
    for (final String word in <String>['one', 'two', 'three']) {
      await tester.tap(find.text(word));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    expect(find.text('Practice complete'), findsOneWidget);
    // Motivation recorded; review state untouched (the boundary).
    expect(progress.snapshot.practiceCount, 1);
    expect(progress.snapshot.practiceXp, 5); // 1 sentence correct × 5
    expect(progress.snapshot.cardsReviewedToday, 0);
    expect(progress.snapshot.totalXp, 0);
  });

  Deck audioDeck() => Deck(
        id: 'au',
        name: 'Audio Deck',
        description: 'd',
        importInfo: DeckImportInfo(
          progressMode: ImportProgressMode.fresh,
          importedAt: DateTime(2026),
        ),
        items: <LearningItem>[
          for (int i = 0; i < 4; i++)
            LearningItem(
                id: 'a$i', front: 'word$i [sound:a$i.mp3]', back: 'meaning $i'),
        ],
      );

  testWidgets(
      'Listening challenge plays through and records practice XP only (MVP_018)',
      (WidgetTester tester) async {
    final _InMemoryProgress progress =
        _InMemoryProgress(DateTime(2026, 6, 22, 10));
    await _pumpApp(tester,
        deckRepository: _FixedDeckRepository(<Deck>[audioDeck()]),
        progressRepository: progress);

    await tester.tap(find.text('Audio Deck').last);
    await tester.pumpAndSettle();
    // Deck detail surfaces the registered Listening mode (audio-rich deck).
    await tester.tap(find.text('Listening'));
    await tester.pumpAndSettle();

    // Play / choose / next through every round (audio is unavailable in test —
    // the challenge still works on the four meaning choices).
    expect(find.textContaining('pick the meaning'), findsOneWidget);
    int guard = 0;
    while (find.text('Listening complete').evaluate().isEmpty && guard < 10) {
      guard++;
      await tester.tap(find.text('meaning 0').first);
      await tester.pumpAndSettle();
      final bool last = find.text('Finish').evaluate().isNotEmpty;
      await tester.tap(find.text(last ? 'Finish' : 'Next'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Listening complete'), findsOneWidget);
    // Motivation recorded; review state untouched (the boundary).
    expect(progress.snapshot.practiceCount, 1);
    expect(progress.snapshot.cardsReviewedToday, 0);
    expect(progress.snapshot.totalXp, 0);
  });

  testWidgets('Home opens the registry-driven practice hub (MVP_017)',
      (WidgetTester tester) async {
    await _pumpApp(tester,
        deckRepository: _FixedDeckRepository(<Deck>[sentenceDeck()]));

    // The Home practice entry appears because a deck supports a mode.
    expect(find.text('Practice modes'), findsOneWidget);
    await tester.tap(find.text('Practice modes'));
    await tester.pumpAndSettle();

    // The hub shows the registered mode (Available now) + the supporting deck.
    expect(find.text('Available now'), findsOneWidget);
    expect(find.text('Sentence builder'), findsWidgets); // the registered mode
    expect(find.text('Sentence Deck'), findsWidgets); // From your decks
  });

  testWidgets('Selected app theme persists across a restart',
      (WidgetTester tester) async {
    final _InMemorySettings settings = _InMemorySettings();
    await _pumpApp(tester, settingsRepository: settings);

    // Default is the light "Soft Study" theme.
    expect(_appBrightness(tester), Brightness.light);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Themes')); // Settings hub → theme gallery
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

    await tester.tap(find.text('Empty Deck').last); // shelf row (also in hero)
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

  testWidgets('Settings and Import tabs open from the floating nav',
      (WidgetTester tester) async {
    await _pumpApp(tester);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Study defaults'), findsOneWidget); // hub
    await tester.tap(find.text('Themes'));
    await tester.pumpAndSettle();
    expect(find.text('App themes'), findsOneWidget);
    expect(find.text('Card themes'), findsOneWidget);

    await tester.tap(find.byTooltip('Import'));
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

  testWidgets('Import preview surfaces diagnostics and warnings (MVP_013)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ImportPreviewPanel(
          preview: const DeckImportPreview(
            deckName: 'Modern Deck',
            totalCards: 5,
            newCards: 5,
            reviewedCards: 0,
            suspendedCards: 0,
            hasProgressData: false,
            diagnostics: ImportDiagnostics(
              format: AnkiPackageFormat.modern21b,
              models: 2,
              templates: 3,
              findings: <ImportDiagnostic>[
                ImportDiagnostic(
                  category: DiagnosticCategory.media,
                  severity: DiagnosticSeverity.warning,
                  message:
                      'Some cards reference sound or images, but Decko found no media in this package — that media may not play or show.',
                ),
              ],
            ),
          ),
          onKeepProgress: () {},
          onStartFresh: () {},
          onCancel: () {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Imported with a few notes'), findsOneWidget); // health
    expect(find.textContaining('media may not play or show'), findsOneWidget);
    expect(find.text('TECHNICAL DETAILS'), findsOneWidget); // progressive
  });

  Widget healthHost(ImportDiagnostics d) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ImportHealthSummary(diagnostics: d),
            ),
          ),
        ),
      );

  testWidgets('Import health: healthy state is reassuring (MVP_014)',
      (WidgetTester tester) async {
    await tester.pumpWidget(healthHost(const ImportDiagnostics(
      format: AnkiPackageFormat.legacy21,
      notes: 10,
      cards: 12,
      templates: 1,
    )));
    await tester.pumpAndSettle();
    expect(find.text('Deck looks good'), findsOneWidget);
    expect(find.text('TECHNICAL DETAILS'), findsOneWidget);
  });

  testWidgets('Import health: warning state groups findings + expands tech',
      (WidgetTester tester) async {
    await tester.pumpWidget(healthHost(const ImportDiagnostics(
      format: AnkiPackageFormat.modern21b,
      notes: 5,
      cards: 6,
      findings: <ImportDiagnostic>[
        ImportDiagnostic(
          category: DiagnosticCategory.media,
          severity: DiagnosticSeverity.warning,
          message: 'Some media is missing.',
          technicalDetail: '2 manifest entries have no payload.',
        ),
      ],
    )));
    await tester.pumpAndSettle();
    expect(find.text('Imported with a few notes'), findsOneWidget);
    expect(find.text('Some media is missing.'), findsOneWidget);

    await tester.tap(find.text('TECHNICAL DETAILS'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Package format'), findsOneWidget);
    expect(find.textContaining('2 manifest entries'), findsOneWidget);
  });

  testWidgets('Import health: blocked state explains the failure',
      (WidgetTester tester) async {
    await tester.pumpWidget(healthHost(const ImportDiagnostics(
      format: AnkiPackageFormat.unknown,
      blockingError: 'No Anki collection was found in this package.',
    )));
    await tester.pumpAndSettle();
    expect(find.text('Couldn’t import this deck'), findsOneWidget);
    expect(find.text('No Anki collection was found in this package.'),
        findsOneWidget);
  });

  testWidgets('Deck detail links to the saved import report (MVP_014)',
      (WidgetTester tester) async {
    final Deck deck = Deck(
      id: 'imp',
      name: 'Imported X',
      description: 'd',
      importInfo: DeckImportInfo(
        progressMode: ImportProgressMode.fresh,
        importedAt: DateTime(2026),
        diagnostics: const ImportDiagnostics(
          format: AnkiPackageFormat.modern21b,
          notes: 3,
          cards: 3,
          findings: <ImportDiagnostic>[
            ImportDiagnostic(
              category: DiagnosticCategory.media,
              severity: DiagnosticSeverity.warning,
              message: 'Some media is missing.',
            ),
          ],
        ),
      ),
      items: const <LearningItem>[LearningItem(id: 'a', front: 'a', back: 'a')],
    );
    await _pumpApp(tester,
        deckRepository: _FixedDeckRepository(<Deck>[deck]));

    await tester.tap(find.text('Imported X').last); // shelf row → deck detail
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import report'));
    await tester.pumpAndSettle();

    expect(find.text('Imported with a few notes'), findsOneWidget); // health
    expect(find.text('Some media is missing.'), findsOneWidget);
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

    await tester.tap(find.text('Imported').last); // the shelf row, not the ribbon
    await tester.pumpAndSettle();

    // Two review cards due/reviewed; total 3.
    expect(find.text('3'), findsOneWidget); // total cards
    expect(find.text('2'), findsNWidgets(2)); // due today + reviewed
    expect(find.text('Progress: kept from Anki'), findsOneWidget);
  });

  testWidgets('Imported deck detail can inspect the preserved Anki source',
      (WidgetTester tester) async {
    final Deck deck = Deck(
      id: 'anki-src',
      name: 'Source Deck',
      description: 'd',
      importInfo: DeckImportInfo(
          progressMode: ImportProgressMode.fresh, importedAt: DateTime(2026)),
      items: const <LearningItem>[LearningItem(id: 'a', front: 'a', back: 'a')],
    );
    final _InMemorySourceStore source = _InMemorySourceStore()
      ..seed(const ImportedAnkiSource(
        deckId: 'anki-src',
        models: <ImportedAnkiModel>[
          ImportedAnkiModel(
            id: 'm1',
            name: 'Japanese Vocab',
            fieldNames: <String>['Reading', 'Sentence'],
            templates: <ImportedAnkiCardTemplate>[
              ImportedAnkiCardTemplate(
                  sourceModelId: 'm1',
                  ordinal: 0,
                  name: 'Listening',
                  questionTemplate: '',
                  answerTemplate: ''),
            ],
          ),
        ],
        notes: <ImportedAnkiNote>[
          ImportedAnkiNote(
            sourceNoteId: '100',
            sourceGuid: 'g',
            sourceModelId: 'm1',
            modelName: 'Japanese Vocab',
            deckId: 'anki-src',
            tags: <String>['n5'],
            fields: <ImportedAnkiField>[
              ImportedAnkiField(
                  name: 'Reading',
                  ordinal: 0,
                  rawValue: '会社',
                  plainTextValue: '会社'),
              ImportedAnkiField(
                  name: 'Sentence',
                  ordinal: 1,
                  rawValue: '会社はどこ',
                  plainTextValue: '会社はどこ'),
            ],
          ),
        ],
        cardSources: <ImportedAnkiCardSource>[
          ImportedAnkiCardSource(
            sourceCardId: '200',
            sourceNoteId: '100',
            sourceDeckId: 'anki-src',
            templateOrdinal: 0,
            templateName: 'Listening',
            queueState: 'newCard',
            due: 0,
            reps: 0,
            lapses: 0,
          ),
        ],
      ));

    await _pumpApp(tester,
        deckRepository: _FixedDeckRepository(<Deck>[deck]),
        importedSourceStore: source);

    await tester.tap(find.text('Source Deck').last); // shelf row → deck detail
    await tester.pumpAndSettle();

    await tester.tap(find.text('View imported source'));
    await tester.pumpAndSettle();

    // The preserved model, fields, tags and template are all on screen.
    expect(find.text('Japanese Vocab'), findsOneWidget);
    expect(find.text('Reading'), findsWidgets);
    expect(find.text('Sentence'), findsWidgets);
    expect(find.text('n5'), findsOneWidget); // preserved tag
    expect(find.text('1. Listening'), findsOneWidget); // template identity
  });

  testWidgets('Deck options open from deck detail and persist an override',
      (WidgetTester tester) async {
    const Deck deck = Deck(
      id: 'opt',
      name: 'Opt Deck',
      description: 'd',
      items: <LearningItem>[
        LearningItem(id: 'a', front: 'a', back: 'a'),
        LearningItem(id: 'b', front: 'b', back: 'b'),
      ],
    );
    final _InMemoryStudyOptionsRepository options =
        _InMemoryStudyOptionsRepository();

    await _pumpApp(tester,
        deckRepository: const _FixedDeckRepository(<Deck>[deck]),
        studyOptionsRepository: options);

    await tester.tap(find.text('Opt Deck').last); // shelf row → deck detail
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deck options'));
    await tester.pumpAndSettle();

    expect(find.text('Options for Opt Deck'), findsOneWidget);
    expect(find.text('Inherited: 20'), findsOneWidget); // new cards/day baseline

    // Turn on the "New cards per day" override (the first switch).
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(options.deckOptions['opt']?.newCardsPerDay, 20); // persisted
  });

  testWidgets('Review session honours persisted daily new-card counts',
      (WidgetTester tester) async {
    const Deck deck = Deck(
      id: 'daily',
      name: 'Daily Deck',
      description: 'd',
      items: <LearningItem>[
        LearningItem(id: 'a', front: 'a', back: 'a'),
        LearningItem(id: 'b', front: 'b', back: 'b'),
        LearningItem(id: 'c', front: 'c', back: 'c'),
      ],
    );
    final _InMemoryStudyOptionsRepository options =
        _InMemoryStudyOptionsRepository()
          ..global = const StudyOptions(newCardsPerDay: 3);
    // Two new cards already studied today → only one remains this session.
    final _InMemoryDailyCountsRepository counts =
        _InMemoryDailyCountsRepository()
          ..seed(
              'daily',
              DailyStudyCounts(day: DailyStudyCounts.dayKey(DateTime.now()))
                  .record(isNew: true)
                  .record(isNew: true));

    await _pumpApp(tester,
        deckRepository: const _FixedDeckRepository(<Deck>[deck]),
        studyOptionsRepository: options,
        dailyStudyCountsRepository: counts);

    await tester.tap(find.text('Daily Deck').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start review'));
    await tester.pumpAndSettle();

    expect(find.text('Card 1 of 1'), findsOneWidget); // 3 limit − 2 today = 1
  });

  testWidgets('Assigning a study profile updates the deck baseline',
      (WidgetTester tester) async {
    const Deck deck = Deck(
      id: 'prof',
      name: 'Prof Deck',
      description: 'd',
      items: <LearningItem>[LearningItem(id: 'a', front: 'a', back: 'a')],
    );
    final _InMemoryStudyOptionsRepository options =
        _InMemoryStudyOptionsRepository()
          ..profiles.add(const StudyOptionProfile(
              id: 'fast',
              name: 'Fast',
              options: StudyOptions(newCardsPerDay: 5)));

    await _pumpApp(tester,
        deckRepository: const _FixedDeckRepository(<Deck>[deck]),
        studyOptionsRepository: options);

    await tester.tap(find.text('Prof Deck').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deck options'));
    await tester.pumpAndSettle();

    // Default baseline first; pick the Fast profile chip.
    expect(find.text('Inherited: 20'), findsOneWidget);
    await tester.tap(find.text('Fast'));
    await tester.pumpAndSettle();

    expect(options.deckOptions['prof']?.profileId, 'fast');
    expect(find.text('Inherited: 5'), findsOneWidget); // baseline now the profile
  });

  testWidgets('Review session respects a small max-session limit',
      (WidgetTester tester) async {
    const Deck deck = Deck(
      id: 'cap',
      name: 'Cap Deck',
      description: 'd',
      items: <LearningItem>[
        LearningItem(id: 'a', front: 'a', back: 'a'),
        LearningItem(id: 'b', front: 'b', back: 'b'),
        LearningItem(id: 'c', front: 'c', back: 'c'),
      ],
    );
    final _InMemoryStudyOptionsRepository options =
        _InMemoryStudyOptionsRepository()
          ..global = const StudyOptions(maxSessionCards: 1);

    await _pumpApp(tester,
        deckRepository: const _FixedDeckRepository(<Deck>[deck]),
        studyOptionsRepository: options);

    await tester.tap(find.text('Cap Deck').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start review'));
    await tester.pumpAndSettle();

    // Three cards available, but the session is capped to one.
    expect(find.text('Card 1 of 1'), findsOneWidget);
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

    await tester.tap(find.text('My Deck').last); // the shelf row, not the ribbon
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

    await tester.tap(find.text('Mid Deck').last); // the shelf row, not the ribbon
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

  testWidgets('Listening card shows a quiet LISTENING eyebrow',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: DeckoCard(
          item: LearningItem(
            id: 'x',
            front: 'listen',
            back: '会社',
            mode: ReviewCardMode.listening,
          ),
          deckId: 'd',
          style: CardThemeStyle.minimal,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('LISTENING'), findsOneWidget);
  });

  testWidgets('Production card prompts in English, hides Japanese until flip',
      (WidgetTester tester) async {
    Widget card({required bool revealed}) => MaterialApp(
          home: Scaffold(
            body: DeckoCard(
              item: const LearningItem(
                id: 'x',
                front: 'company',
                back: '会社',
                mode: ReviewCardMode.production,
              ),
              deckId: 'd',
              style: CardThemeStyle.minimal,
              revealed: revealed,
            ),
          ),
        );

    await tester.pumpWidget(card(revealed: false));
    await tester.pumpAndSettle();
    expect(find.text('PRODUCTION'), findsOneWidget);
    expect(find.text('company'), findsOneWidget); // English prompt
    expect(find.text('会社'), findsNothing); // Japanese hidden before flip

    await tester.pumpWidget(card(revealed: true));
    await tester.pumpAndSettle();
    expect(find.text('会社'), findsOneWidget); // revealed on the back
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
    // Demo decks remain (in the ribbon and/or the shelf row).
    expect(find.text('Japanese Starter Deck'), findsWidgets);
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

    await tester.tap(find.text('Future Deck').last); // shelf row (also in hero)
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

    await tester.tap(find.text('Mixed Deck').last); // the shelf row, not the ribbon
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start review'));
    await tester.pumpAndSettle();

    // Only the non-suspended due card is in the queue.
    expect(find.text('Card 1 of 1'), findsOneWidget);
  });
}

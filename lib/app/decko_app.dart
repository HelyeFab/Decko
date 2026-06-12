import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/decko_strings.dart';
import '../data/mock_deck_repository.dart';
import '../data/shared_prefs_progress_repository.dart';
import '../data/shared_prefs_settings_repository.dart';
import '../domain/repositories/deck_repository.dart';
import '../domain/repositories/progress_repository.dart';
import '../domain/repositories/settings_repository.dart';
import 'deck_store.dart';
import 'decko_router.dart';
import 'theme/app_theme_config.dart';
import 'theme/theme_controller.dart';

/// Root Decko widget.
///
/// Owns the app-wide dependencies — the [ThemeController], the [DeckStore]
/// (demo + imported decks), [SettingsRepository] and [ProgressRepository] — and
/// rebuilds the [MaterialApp.router] when the selected theme changes.
/// Dependencies are handed to the tree via a [_DeckoScope]; the static
/// `*Of(context)` helpers read them. The injected [deckRepository] provides the
/// demo decks the store wraps, so tests can supply in-memory fakes.
class DeckoApp extends StatefulWidget {
  const DeckoApp({
    super.key,
    this.deckRepository = const MockDeckRepository(),
    this.settingsRepository = const SharedPrefsSettingsRepository(),
    this.progressRepository = const SharedPrefsProgressRepository(),
  });

  final DeckRepository deckRepository;
  final SettingsRepository settingsRepository;
  final ProgressRepository progressRepository;

  static ThemeController themeOf(BuildContext context) =>
      _scopeOf(context).controller;

  static DeckRepository repositoryOf(BuildContext context) =>
      _scopeOf(context).deckStore;

  static DeckStore deckStoreOf(BuildContext context) =>
      _scopeOf(context).deckStore;

  static ProgressRepository progressOf(BuildContext context) =>
      _scopeOf(context).progressRepository;

  static _DeckoScope _scopeOf(BuildContext context) {
    final _DeckoScope? scope =
        context.dependOnInheritedWidgetOfExactType<_DeckoScope>();
    assert(scope != null, 'DeckoApp dependency looked up outside a DeckoApp');
    return scope!;
  }

  @override
  State<DeckoApp> createState() => _DeckoAppState();
}

class _DeckoAppState extends State<DeckoApp> {
  late final ThemeController _themeController;
  late final DeckStore _deckStore;
  final GoRouter _router = buildDeckoRouter();

  @override
  void initState() {
    super.initState();
    _themeController = ThemeController(widget.settingsRepository);
    _themeController.load();
    _deckStore = DeckStore(demoDecks: widget.deckRepository);
    _deckStore.load();
  }

  @override
  void dispose() {
    _themeController.dispose();
    _deckStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DeckoScope(
      controller: _themeController,
      deckStore: _deckStore,
      progressRepository: widget.progressRepository,
      child: ValueListenableBuilder<AppThemeConfig>(
        valueListenable: _themeController,
        builder: (BuildContext context, AppThemeConfig appTheme, _) {
          return MaterialApp.router(
            title: DeckoStrings.wordmark,
            debugShowCheckedModeBanner: false,
            theme: appTheme.themeData,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}

/// Inherited handle to the app's shared dependencies.
class _DeckoScope extends InheritedWidget {
  const _DeckoScope({
    required this.controller,
    required this.deckStore,
    required this.progressRepository,
    required super.child,
  });

  final ThemeController controller;
  final DeckStore deckStore;
  final ProgressRepository progressRepository;

  @override
  bool updateShouldNotify(_DeckoScope oldWidget) =>
      controller != oldWidget.controller ||
      deckStore != oldWidget.deckStore ||
      progressRepository != oldWidget.progressRepository;
}

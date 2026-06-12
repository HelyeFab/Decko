import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/decko_strings.dart';
import '../data/mock_deck_repository.dart';
import '../domain/repositories/deck_repository.dart';
import 'decko_router.dart';
import 'theme/app_theme_config.dart';
import 'theme/theme_controller.dart';

/// Root Decko widget.
///
/// Owns the app-wide dependencies — the [ThemeController] and the
/// [DeckRepository] — and rebuilds the [MaterialApp.router] whenever the
/// selected app theme changes. Dependencies are handed to the widget tree via a
/// [_DeckoScope] inherited widget, mirrored by [themeOf]/[repositoryOf] so
/// screens (and GoRouter builders) can reach them without constructor wiring.
class DeckoApp extends StatefulWidget {
  const DeckoApp({super.key, this.deckRepository = const MockDeckRepository()});

  /// Injectable so tests (and later, a persistent impl) can override it.
  final DeckRepository deckRepository;

  /// Looks up the nearest [ThemeController].
  static ThemeController themeOf(BuildContext context) =>
      _scopeOf(context).controller;

  /// Looks up the nearest [DeckRepository].
  static DeckRepository repositoryOf(BuildContext context) =>
      _scopeOf(context).repository;

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
  final ThemeController _themeController = ThemeController();
  final GoRouter _router = buildDeckoRouter();

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DeckoScope(
      controller: _themeController,
      repository: widget.deckRepository,
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
    required this.repository,
    required super.child,
  });

  final ThemeController controller;
  final DeckRepository repository;

  @override
  bool updateShouldNotify(_DeckoScope oldWidget) =>
      controller != oldWidget.controller ||
      repository != oldWidget.repository;
}

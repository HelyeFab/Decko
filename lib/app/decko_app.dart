import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/decko_strings.dart';
import 'decko_router.dart';
import 'theme/app_theme_config.dart';
import 'theme/theme_controller.dart';

/// Root Decko widget.
///
/// Owns the [ThemeController] and rebuilds the [MaterialApp.router] whenever the
/// selected app theme changes. The controller is handed down to the widget tree
/// via [DeckoApp.themeOf] so screens (e.g. the gallery) can change themes.
class DeckoApp extends StatefulWidget {
  const DeckoApp({super.key});

  /// Looks up the nearest [ThemeController] from the element tree.
  static ThemeController themeOf(BuildContext context) {
    final _ThemeScope? scope =
        context.dependOnInheritedWidgetOfExactType<_ThemeScope>();
    assert(scope != null, 'DeckoApp.themeOf called outside a DeckoApp');
    return scope!.controller;
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
    return _ThemeScope(
      controller: _themeController,
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

/// Inherited handle to the [ThemeController] for descendants.
class _ThemeScope extends InheritedWidget {
  const _ThemeScope({required this.controller, required super.child});

  final ThemeController controller;

  @override
  bool updateShouldNotify(_ThemeScope oldWidget) =>
      controller != oldWidget.controller;
}

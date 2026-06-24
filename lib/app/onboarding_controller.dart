import 'package:flutter/foundation.dart';

import '../domain/repositories/settings_repository.dart';

/// Tracks whether first-run onboarding is complete (MVP_024). Local-only and
/// independent of auth — signing out never resets it. The router gates on
/// [isComplete]; [initial] is the value loaded at startup so there's no flash.
class OnboardingController extends ChangeNotifier {
  OnboardingController(this._settings, {bool? initial})
      : _complete = initial ?? true {
    if (initial == null) _load();
  }

  final SettingsRepository _settings;
  bool _complete;

  bool get isComplete => _complete;

  Future<void> _load() async {
    final bool v = await _settings.getHasCompletedOnboarding();
    if (v != _complete) {
      _complete = v;
      notifyListeners();
    }
  }

  /// Marks onboarding finished (or skipped) and persists it.
  Future<void> complete() async {
    if (!_complete) {
      _complete = true;
      notifyListeners();
    }
    await _settings.saveHasCompletedOnboarding(true);
  }
}

import 'package:flutter/foundation.dart';

import '../domain/repositories/settings_repository.dart';

/// Holds the "show furigana" preference, persists changes, and notifies
/// listeners so cards re-render when it is toggled. Defaults to on; hydrated
/// once at startup via [load].
class FuriganaController extends ValueNotifier<bool> {
  FuriganaController(this._settings) : super(true);

  final SettingsRepository _settings;

  Future<void> load() async {
    value = await _settings.getShowFurigana();
  }

  void toggle() {
    value = !value;
    _settings.saveShowFurigana(value);
  }
}

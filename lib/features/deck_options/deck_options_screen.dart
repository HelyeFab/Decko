import 'package:flutter/material.dart';

import '../../app/decko_app.dart';
import '../../core/constants/decko_spacing.dart';
import '../../core/widgets/decko_app_bar.dart';
import '../../domain/repositories/study_options_repository.dart';
import '../../domain/study_options/study_options.dart';
import '../settings/widgets/option_controls.dart';

/// Per-deck study overrides (MVP_011). Each option either follows the global
/// default or is overridden for this deck. Changes persist immediately.
class DeckOptionsScreen extends StatefulWidget {
  const DeckOptionsScreen({
    super.key,
    required this.deckId,
    required this.deckName,
  });

  final String deckId;
  final String deckName;

  @override
  State<DeckOptionsScreen> createState() => _DeckOptionsScreenState();
}

class _DeckOptionsScreenState extends State<DeckOptionsScreen> {
  StudyOptionsRepository? _repo;
  StudyOptions? _global;
  DeckStudyOptions _deck = DeckStudyOptions.none;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repo ??= DeckoApp.studyOptionsOf(context);
    if (!_loaded) _load();
  }

  Future<void> _load() async {
    final StudyOptions g = await _repo!.getGlobalOptions();
    final DeckStudyOptions? d = await _repo!.getDeckOptions(widget.deckId);
    if (!mounted) return;
    setState(() {
      _global = g;
      _deck = d ?? DeckStudyOptions.none;
      _loaded = true;
    });
  }

  void _update(DeckStudyOptions next) {
    setState(() => _deck = next);
    _repo!.saveDeckOptions(widget.deckId, next);
  }

  @override
  Widget build(BuildContext context) {
    final StudyOptions? g = _global;
    return Scaffold(
      appBar: const DeckoAppBar(title: 'Deck options'),
      body: SafeArea(
        child: !_loaded || g == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  DeckoSpacing.pagePadding,
                  DeckoSpacing.lg,
                  DeckoSpacing.pagePadding,
                  DeckoSpacing.xxxl,
                ),
                children: <Widget>[
                  Text(
                    'Options for ${widget.deckName}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: DeckoSpacing.xs),
                  Text(
                    'Override the global defaults just for this deck.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: DeckoSpacing.lg),
                  SettingsSection(
                    title: 'Daily study limits',
                    children: <Widget>[
                      _intOverride(
                        label: 'New cards per day',
                        deckValue: _deck.newCardsPerDay,
                        globalValue: g.newCardsPerDay,
                        max: 1000,
                        step: 5,
                        apply: (int? v) =>
                            _update(_deck.copyWith(newCardsPerDay: v)),
                      ),
                      _intOverride(
                        label: 'Reviews per day',
                        deckValue: _deck.reviewCardsPerDay,
                        globalValue: g.reviewCardsPerDay,
                        max: 9999,
                        step: 25,
                        apply: (int? v) =>
                            _update(_deck.copyWith(reviewCardsPerDay: v)),
                      ),
                      _intOverride(
                        label: 'Maximum cards in one session',
                        deckValue: _deck.maxSessionCards,
                        globalValue: g.maxSessionCards,
                        max: 9999,
                        step: 10,
                        apply: (int? v) =>
                            _update(_deck.copyWith(maxSessionCards: v)),
                      ),
                    ],
                  ),
                  const SizedBox(height: DeckoSpacing.xl),
                  SettingsSection(
                    title: 'Media',
                    children: <Widget>[
                      _enumOverride<AudioAutoplayMode>(
                        label: 'Play audio automatically',
                        deckValue: _deck.audioAutoplayMode,
                        globalValue: g.audioAutoplayMode,
                        choices: const <(String, AudioAutoplayMode)>[
                          ('Off', AudioAutoplayMode.off),
                          ('On the question', AudioAutoplayMode.beforeQuestion),
                          ('After the answer', AudioAutoplayMode.afterReveal),
                        ],
                        labelOf: _audioLabel,
                        apply: (AudioAutoplayMode? v) =>
                            _update(_deck.copyWith(audioAutoplayMode: v)),
                      ),
                      _enumOverride<ImageDisplayMode>(
                        label: 'Show images',
                        deckValue: _deck.imageDisplayMode,
                        globalValue: g.imageDisplayMode,
                        choices: const <(String, ImageDisplayMode)>[
                          ('Before answering', ImageDisplayMode.withQuestion),
                          ('After the answer', ImageDisplayMode.afterReveal),
                        ],
                        labelOf: _imageLabel,
                        apply: (ImageDisplayMode? v) =>
                            _update(_deck.copyWith(imageDisplayMode: v)),
                      ),
                    ],
                  ),
                  const SizedBox(height: DeckoSpacing.xl),
                  SettingsSection(
                    title: 'Reading aids',
                    children: <Widget>[
                      ChoiceRow<FuriganaPreference>(
                        label: 'Furigana for this deck',
                        value: _deck.furiganaPreference,
                        choices: const <(String, FuriganaPreference)>[
                          ('Use global', FuriganaPreference.useGlobal),
                          ('Always show', FuriganaPreference.alwaysShow),
                          ('Always hide', FuriganaPreference.alwaysHide),
                        ],
                        onChanged: (FuriganaPreference v) =>
                            _update(_deck.copyWith(furiganaPreference: v)),
                      ),
                    ],
                  ),
                  const SizedBox(height: DeckoSpacing.xl),
                  SettingsSection(
                    title: 'Related cards',
                    children: <Widget>[
                      _boolOverride(
                        label: 'Bury related cards until tomorrow',
                        deckValue: _deck.burySiblingsUntilTomorrow,
                        globalValue: g.burySiblingsUntilTomorrow,
                        apply: (bool? v) => _update(
                            _deck.copyWith(burySiblingsUntilTomorrow: v)),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _intOverride({
    required String label,
    required int? deckValue,
    required int globalValue,
    required int max,
    required int step,
    required ValueChanged<int?> apply,
  }) {
    final bool overridden = deckValue != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SwitchRow(
          label: label,
          subtitle: overridden ? null : 'Using global: $globalValue',
          value: overridden,
          onChanged: (bool on) => apply(on ? globalValue : null),
        ),
        if (overridden)
          StepperRow(
            label: 'This deck',
            value: deckValue,
            max: max,
            step: step,
            onChanged: (int v) => apply(v),
          ),
      ],
    );
  }

  Widget _enumOverride<T>({
    required String label,
    required T? deckValue,
    required T globalValue,
    required List<(String, T)> choices,
    required String Function(T) labelOf,
    required ValueChanged<T?> apply,
  }) {
    final bool overridden = deckValue != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SwitchRow(
          label: label,
          subtitle: overridden ? null : 'Using global: ${labelOf(globalValue)}',
          value: overridden,
          onChanged: (bool on) => apply(on ? globalValue : null),
        ),
        if (overridden)
          ChoiceRow<T>(
            label: 'This deck',
            value: deckValue as T,
            choices: choices,
            onChanged: (T v) => apply(v),
          ),
      ],
    );
  }

  Widget _boolOverride({
    required String label,
    required bool? deckValue,
    required bool globalValue,
    required ValueChanged<bool?> apply,
  }) {
    final bool overridden = deckValue != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SwitchRow(
          label: 'Override “$label”',
          subtitle: overridden
              ? null
              : 'Using global: ${globalValue ? 'On' : 'Off'}',
          value: overridden,
          onChanged: (bool on) => apply(on ? globalValue : null),
        ),
        if (overridden)
          SwitchRow(
            label: label,
            value: deckValue,
            onChanged: (bool v) => apply(v),
          ),
      ],
    );
  }

  static String _audioLabel(AudioAutoplayMode m) => switch (m) {
        AudioAutoplayMode.off => 'Off',
        AudioAutoplayMode.beforeQuestion => 'On the question',
        AudioAutoplayMode.afterReveal => 'After the answer',
      };

  static String _imageLabel(ImageDisplayMode m) => switch (m) {
        ImageDisplayMode.withQuestion => 'Before answering',
        ImageDisplayMode.afterReveal => 'After the answer',
      };
}

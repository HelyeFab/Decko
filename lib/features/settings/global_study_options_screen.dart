import 'package:flutter/material.dart';

import '../../app/decko_app.dart';
import '../../core/constants/decko_spacing.dart';
import '../../core/widgets/decko_app_bar.dart';
import '../../domain/repositories/study_options_repository.dart';
import '../../domain/study_options/study_options.dart';
import 'widgets/option_controls.dart';

/// Global study defaults for every deck (MVP_011). Changes persist immediately.
class GlobalStudyOptionsScreen extends StatefulWidget {
  const GlobalStudyOptionsScreen({super.key});

  @override
  State<GlobalStudyOptionsScreen> createState() =>
      _GlobalStudyOptionsScreenState();
}

class _GlobalStudyOptionsScreenState extends State<GlobalStudyOptionsScreen> {
  StudyOptionsRepository? _repo;
  StudyOptions? _options;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repo ??= DeckoApp.studyOptionsOf(context);
    if (_options == null) _load();
  }

  Future<void> _load() async {
    final StudyOptions o = await _repo!.getGlobalOptions();
    if (mounted) setState(() => _options = o);
  }

  void _update(StudyOptions next) {
    setState(() => _options = next);
    _repo!.saveGlobalOptions(next);
  }

  @override
  Widget build(BuildContext context) {
    final StudyOptions? o = _options;
    return Scaffold(
      appBar: const DeckoAppBar(title: 'Study defaults'),
      body: SafeArea(
        child: o == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  DeckoSpacing.pagePadding,
                  DeckoSpacing.lg,
                  DeckoSpacing.pagePadding,
                  DeckoSpacing.xxxl,
                ),
                children: <Widget>[
                  SettingsSection(
                    title: 'Daily study limits',
                    subtitle: 'Applied to each review session.',
                    children: <Widget>[
                      StepperRow(
                        label: 'New cards per day',
                        value: o.newCardsPerDay,
                        max: 1000,
                        onChanged: (int v) =>
                            _update(o.copyWith(newCardsPerDay: v)),
                      ),
                      StepperRow(
                        label: 'Reviews per day',
                        value: o.reviewCardsPerDay,
                        step: 25,
                        max: 9999,
                        onChanged: (int v) =>
                            _update(o.copyWith(reviewCardsPerDay: v)),
                      ),
                      StepperRow(
                        label: 'Maximum cards in one session',
                        value: o.maxSessionCards,
                        step: 10,
                        max: 9999,
                        onChanged: (int v) =>
                            _update(o.copyWith(maxSessionCards: v)),
                      ),
                    ],
                  ),
                  const SizedBox(height: DeckoSpacing.xl),
                  SettingsSection(
                    title: 'Media',
                    children: <Widget>[
                      ChoiceRow<AudioAutoplayMode>(
                        label: 'Play audio automatically',
                        value: o.audioAutoplayMode,
                        choices: const <(String, AudioAutoplayMode)>[
                          ('Off', AudioAutoplayMode.off),
                          ('On the question', AudioAutoplayMode.beforeQuestion),
                          ('After the answer', AudioAutoplayMode.afterReveal),
                        ],
                        onChanged: (AudioAutoplayMode v) =>
                            _update(o.copyWith(audioAutoplayMode: v)),
                      ),
                      ChoiceRow<ImageDisplayMode>(
                        label: 'Show images',
                        value: o.imageDisplayMode,
                        choices: const <(String, ImageDisplayMode)>[
                          ('Before answering', ImageDisplayMode.withQuestion),
                          ('After the answer', ImageDisplayMode.afterReveal),
                        ],
                        onChanged: (ImageDisplayMode v) =>
                            _update(o.copyWith(imageDisplayMode: v)),
                      ),
                    ],
                  ),
                  const SizedBox(height: DeckoSpacing.xl),
                  SettingsSection(
                    title: 'Related cards',
                    children: <Widget>[
                      SwitchRow(
                        label: 'Bury related cards until tomorrow',
                        subtitle:
                            'Hold other cards from the same note for a day.',
                        value: o.burySiblingsUntilTomorrow,
                        onChanged: (bool v) =>
                            _update(o.copyWith(burySiblingsUntilTomorrow: v)),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

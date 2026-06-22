import 'package:flutter/material.dart';

import '../../../core/constants/decko_spacing.dart';
import '../../../domain/study_options/study_options.dart';
import 'option_controls.dart';

/// The editable form for a [StudyOptions] set — shared by the global defaults
/// screen and the profile editor (MVP_012). Advanced controls are collapsed.
class StudyOptionsForm extends StatelessWidget {
  const StudyOptionsForm({
    super.key,
    required this.options,
    required this.onChanged,
  });

  final StudyOptions options;
  final ValueChanged<StudyOptions> onChanged;

  @override
  Widget build(BuildContext context) {
    final StudyOptions o = options;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SettingsSection(
          title: 'Daily study limits',
          subtitle: 'Applied per day, across sessions.',
          children: <Widget>[
            StepperRow(
              label: 'New cards per day',
              value: o.newCardsPerDay,
              max: 1000,
              onChanged: (int v) => onChanged(o.copyWith(newCardsPerDay: v)),
            ),
            StepperRow(
              label: 'Reviews per day',
              value: o.reviewCardsPerDay,
              step: 25,
              max: 9999,
              onChanged: (int v) => onChanged(o.copyWith(reviewCardsPerDay: v)),
            ),
            StepperRow(
              label: 'Maximum cards in one session',
              value: o.maxSessionCards,
              step: 10,
              max: 9999,
              onChanged: (int v) => onChanged(o.copyWith(maxSessionCards: v)),
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
                  onChanged(o.copyWith(audioAutoplayMode: v)),
            ),
            ChoiceRow<ImageDisplayMode>(
              label: 'Show images',
              value: o.imageDisplayMode,
              choices: const <(String, ImageDisplayMode)>[
                ('Before answering', ImageDisplayMode.withQuestion),
                ('After the answer', ImageDisplayMode.afterReveal),
              ],
              onChanged: (ImageDisplayMode v) =>
                  onChanged(o.copyWith(imageDisplayMode: v)),
            ),
          ],
        ),
        const SizedBox(height: DeckoSpacing.xl),
        SettingsSection(
          title: 'Sentence builder',
          children: <Widget>[
            SwitchRow(
              label: 'Review sentences as a builder',
              subtitle:
                  'Cards with a sentence are tested by rebuilding it. Grading '
                  'is unchanged.',
              value: o.sentenceBuilderReview,
              onChanged: (bool v) =>
                  onChanged(o.copyWith(sentenceBuilderReview: v)),
            ),
          ],
        ),
        const SizedBox(height: DeckoSpacing.xl),
        _Advanced(
          children: <Widget>[
            ChoiceRow<NewCardOrder>(
              label: 'New card order',
              value: o.newCardOrder,
              choices: const <(String, NewCardOrder)>[
                ('In deck order', NewCardOrder.deckOrder),
                ('Random', NewCardOrder.random),
              ],
              onChanged: (NewCardOrder v) =>
                  onChanged(o.copyWith(newCardOrder: v)),
            ),
            SwitchRow(
              label: 'Bury related cards until tomorrow',
              subtitle: 'Hold other cards from the same note for a day.',
              value: o.burySiblingsUntilTomorrow,
              onChanged: (bool v) =>
                  onChanged(o.copyWith(burySiblingsUntilTomorrow: v)),
            ),
          ],
        ),
      ],
    );
  }
}

/// A collapsed "Advanced scheduling" disclosure (progressive disclosure).
class _Advanced extends StatefulWidget {
  const _Advanced({required this.children});

  final List<Widget> children;

  @override
  State<_Advanced> createState() => _AdvancedState();
}

class _AdvancedState extends State<_Advanced> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InkWell(
          borderRadius: BorderRadius.circular(DeckoRadii.sm),
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: DeckoSpacing.xs),
            child: Row(
              children: <Widget>[
                Text(
                  'ADVANCED SCHEDULING',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Icon(_open ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
        if (_open) ...<Widget>[
          const SizedBox(height: DeckoSpacing.sm),
          SettingsSection(title: 'Related cards', children: widget.children),
        ],
      ],
    );
  }
}

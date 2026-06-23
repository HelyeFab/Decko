import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../app/decko_app.dart';
import '../../app/decko_router.dart';
import '../../app/furigana_controller.dart';
import '../../core/constants/decko_spacing.dart';
import '../../core/constants/decko_strings.dart';
import '../../core/widgets/decko_app_bar.dart';

/// The Settings tab: a calm hub linking to study defaults and themes, plus the
/// global furigana toggle (MVP_011).
class SettingsHubScreen extends StatelessWidget {
  const SettingsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FuriganaController furigana = DeckoApp.furiganaOf(context);
    return Scaffold(
      appBar: const DeckoAppBar(title: 'Settings'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            DeckoSpacing.pagePadding,
            DeckoSpacing.lg,
            DeckoSpacing.pagePadding,
            DeckoSpacing.xxxl,
          ),
          children: <Widget>[
            _SettingsTile(
              icon: FontAwesomeIcons.cloudArrowUp,
              title: 'Account & sync',
              subtitle: 'Protect your progress across devices',
              onTap: () => context.push(DeckoRoutes.account),
            ),
            const SizedBox(height: DeckoSpacing.md),
            _SettingsTile(
              icon: FontAwesomeIcons.sliders,
              title: 'Study defaults',
              subtitle: 'Daily limits, audio, and images for every deck',
              onTap: () => context.push(DeckoRoutes.studyDefaults),
            ),
            const SizedBox(height: DeckoSpacing.md),
            _SettingsTile(
              icon: FontAwesomeIcons.solidStar,
              title: 'Study profiles',
              subtitle: 'Reusable settings shared across decks',
              onTap: () => context.push(DeckoRoutes.studyProfiles),
            ),
            const SizedBox(height: DeckoSpacing.md),
            _SettingsTile(
              icon: FontAwesomeIcons.palette,
              title: 'Themes',
              subtitle: 'App and card appearance',
              onTap: () => context.push(DeckoRoutes.themes),
            ),
            const SizedBox(height: DeckoSpacing.xl),
            const _DailyGoalControl(),
            const SizedBox(height: DeckoSpacing.md),
            ValueListenableBuilder<bool>(
              valueListenable: furigana,
              builder: (BuildContext context, bool on, _) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DeckoSpacing.lg,
                    vertical: DeckoSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(DeckoRadii.lg),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('Show furigana',
                                style: Theme.of(context).textTheme.bodyLarge),
                            Text(
                              'Readings above kanji, for decks that have them',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Switch(value: on, onChanged: (_) => furigana.toggle()),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: DeckoSpacing.xl),
            Center(
              child: Text(
                DeckoStrings.wordmark,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 1,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A motivational daily-goal stepper (MVP_015). Saves to settings; it never
/// affects scheduling or the due queue.
class _DailyGoalControl extends StatefulWidget {
  const _DailyGoalControl();

  @override
  State<_DailyGoalControl> createState() => _DailyGoalControlState();
}

class _DailyGoalControlState extends State<_DailyGoalControl> {
  static const int _min = 5;
  static const int _max = 100;
  static const int _step = 5;
  int? _goal;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_goal == null) _load();
  }

  Future<void> _load() async {
    final int g = await DeckoApp.settingsOf(context).getDailyGoal();
    if (mounted) setState(() => _goal = g);
  }

  void _set(int next) {
    final int clamped = next.clamp(_min, _max);
    setState(() => _goal = clamped);
    DeckoApp.settingsOf(context).saveDailyGoal(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final int goal = _goal ?? 20;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DeckoSpacing.lg,
        vertical: DeckoSpacing.md,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(DeckoRadii.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Daily goal', style: theme.textTheme.bodyLarge),
                Text(
                  'Cards to review each day — motivation only',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: goal > _min ? () => _set(goal - _step) : null,
            icon: const FaIcon(FontAwesomeIcons.minus, size: 14),
            tooltip: 'Decrease',
          ),
          SizedBox(
            width: 44,
            child: Text(
              '$goal',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            onPressed: goal < _max ? () => _set(goal + _step) : null,
            icon: const FaIcon(FontAwesomeIcons.plus, size: 14),
            tooltip: 'Increase',
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final FaIconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(DeckoRadii.lg),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(DeckoSpacing.lg),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(DeckoRadii.lg),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: <Widget>[
              Container(
                height: 44,
                width: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(DeckoRadii.md),
                ),
                child: FaIcon(icon,
                    size: 18, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: DeckoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              FaIcon(FontAwesomeIcons.chevronRight,
                  size: 14, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

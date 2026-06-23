import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../app/decko_app.dart';
import '../../core/widgets/decko_app_bar.dart';
import '../../core/constants/decko_spacing.dart';
import '../../core/widgets/achievement_badge.dart';
import '../../core/widgets/section_header.dart';
import '../../domain/achievement.dart';
import '../../domain/activity/activity_event.dart';
import '../../domain/activity/activity_progress.dart';
import '../../domain/activity/activity_progress_calculator.dart';
import 'widgets/activity_heatmap.dart';
import 'widgets/recent_activity_list.dart';

/// Decko's progress & light-gamification screen, backed by the activity ledger
/// (MVP_019). XP / streaks / heatmap / recent activity are all derived from the
/// ledger; this never drives scheduling. A warm empty state precedes any
/// recorded activity.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

typedef _ProgressData = ({ActivityProgress progress, int goal, DateTime now});

class _ProgressScreenState extends State<ProgressScreen> {
  static const ActivityProgressCalculator _calc = ActivityProgressCalculator();
  Future<_ProgressData>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<_ProgressData> _load() async {
    // Capture before awaiting so we don't use context across the gap.
    final ledger = DeckoApp.ledgerOf(context);
    final settingsRepo = DeckoApp.settingsOf(context);
    final DateTime now = DateTime.now();
    final ActivityProgress progress = _calc.calculate(
      await ledger.allEvents(),
      now,
    );
    final int goal = await settingsRepo.getDailyGoal();
    return (progress: progress, goal: goal, now: now);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DeckoAppBar(title: 'Your progress'),
      body: SafeArea(
        child: FutureBuilder<_ProgressData>(
          future: _future,
          builder: (BuildContext context,
              AsyncSnapshot<_ProgressData> async) {
            if (!async.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final _ProgressData d = async.data!;
            return ListView(
              padding: const EdgeInsets.all(DeckoSpacing.pagePadding),
              children: d.progress.hasActivity
                  ? _progressViews(d.progress, d.goal, d.now)
                  : _emptyViews(d.goal, d.now),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _progressViews(ActivityProgress p, int goal, DateTime now) {
    return <Widget>[
      ActivityHeatmap(days: p.heatmap, today: now),
      const SizedBox(height: DeckoSpacing.lg),
      _DailyGoalCard(reviewed: p.activityToday, goal: goal),
      const SizedBox(height: DeckoSpacing.lg),
      _LevelCard(
        xp: p.totalXp,
        level: p.currentLevel,
        xpIntoLevel: p.xpIntoLevel,
        reviewXp: p.reviewXp,
        practiceXp: p.practiceXp,
      ),
      const SizedBox(height: DeckoSpacing.lg),
      Row(
        children: <Widget>[
          Expanded(
            child: _StatCard(
              icon: FontAwesomeIcons.fire,
              value: '${p.currentStreakDays} '
                  '${p.currentStreakDays == 1 ? 'day' : 'days'}',
              label: 'Current streak',
              footnote: p.currentStreakDays == 0
                  ? 'Study today to start one'
                  : p.reviewedToday || p.practiceRoundsToday > 0
                      ? 'Counted today'
                      : 'Study today to keep it',
            ),
          ),
          const SizedBox(width: DeckoSpacing.md),
          Expanded(
            child: _StatCard(
              icon: FontAwesomeIcons.bolt,
              value: '${p.xpToday}',
              label: 'XP today',
            ),
          ),
        ],
      ),
      if (p.recent.isNotEmpty) ...<Widget>[
        const SizedBox(height: DeckoSpacing.xxl),
        const SectionHeader(title: 'Recent activity'),
        const SizedBox(height: DeckoSpacing.md),
        RecentActivityList(events: p.recent, now: now),
      ],
      const SizedBox(height: DeckoSpacing.xxl),
      const SectionHeader(
        title: 'Achievements',
        subtitle: 'Milestones you’ll unlock as you study.',
      ),
      const SizedBox(height: DeckoSpacing.lg),
      _AchievementsGrid(statuses: achievementsForActivity(p, goal)),
    ];
  }

  List<Widget> _emptyViews(int goal, DateTime now) {
    return <Widget>[
      const _EmptyProgress(),
      const SizedBox(height: DeckoSpacing.lg),
      _DailyGoalCard(reviewed: 0, goal: goal),
      const SizedBox(height: DeckoSpacing.lg),
      ActivityHeatmap(
          days: _calc.calculate(const <ActivityEvent>[], now).heatmap,
          today: now),
      const SizedBox(height: DeckoSpacing.xxl),
      const SectionHeader(
        title: 'Achievements',
        subtitle: 'Milestones you’ll unlock as you study.',
      ),
      const SizedBox(height: DeckoSpacing.lg),
      _AchievementsGrid(
          statuses: achievementsForActivity(ActivityProgress.empty, goal)),
    ];
  }
}

/// The motivational daily goal — a progress ring toward today's target, with a
/// warm "reached" state. Not an Anki daily limit; purely presentation.
class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard({required this.reviewed, required this.goal});

  final int reviewed;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool done = goal > 0 && reviewed >= goal;
    final double progress =
        goal <= 0 ? 1 : (reviewed / goal).clamp(0, 1).toDouble();
    final Color bg = done ? scheme.primaryContainer : theme.cardColor;
    final Color onBg = done ? scheme.onPrimaryContainer : scheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(DeckoSpacing.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DeckoRadii.lg),
        border: done ? null : Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            height: 64,
            width: 64,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                SizedBox(
                  height: 64,
                  width: 64,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 7,
                    strokeCap: StrokeCap.round,
                    backgroundColor: done
                        ? scheme.onPrimaryContainer.withValues(alpha: 0.18)
                        : scheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        done ? scheme.onPrimaryContainer : scheme.primary),
                  ),
                ),
                if (done)
                  FaIcon(FontAwesomeIcons.check,
                      size: 22, color: scheme.onPrimaryContainer)
                else
                  Text(
                    '$reviewed',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: onBg, fontWeight: FontWeight.w800),
                  ),
              ],
            ),
          ),
          const SizedBox(width: DeckoSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  done ? 'Daily goal reached!' : 'Daily goal',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: onBg, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  done
                      ? 'Nice work — you studied $reviewed cards today.'
                      : '$reviewed of $goal cards reviewed today',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: onBg.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The starter achievements as a 2-column grid of badges.
class _AchievementsGrid extends StatelessWidget {
  const _AchievementsGrid({required this.statuses});

  final List<AchievementStatus> statuses;

  static const Map<Achievement, FaIconData> _icons = <Achievement, FaIconData>{
    Achievement.firstReview: FontAwesomeIcons.flag,
    Achievement.dailyGoal: FontAwesomeIcons.bullseye,
    Achievement.threeDayStreak: FontAwesomeIcons.fire,
    Achievement.hundredCards: FontAwesomeIcons.trophy,
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: DeckoSpacing.lg,
      runSpacing: DeckoSpacing.lg,
      alignment: WrapAlignment.spaceBetween,
      children: <Widget>[
        for (final AchievementStatus a in statuses)
          AchievementBadge(
            icon: _icons[a.achievement]!,
            label: a.achievement.title,
            earned: a.earned,
          ),
      ],
    );
  }
}

class _EmptyProgress extends StatelessWidget {
  const _EmptyProgress();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DeckoSpacing.xl),
        child: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(DeckoSpacing.lg),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(DeckoRadii.md),
              ),
              child: FaIcon(
                FontAwesomeIcons.rocket,
                size: 36,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: DeckoSpacing.lg),
            Text(
              'No progress yet',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: DeckoSpacing.xs),
            Text(
              'Complete your first review session to start building your '
              'Decko streak.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.xp,
    required this.level,
    required this.xpIntoLevel,
    required this.reviewXp,
    required this.practiceXp,
  });

  final int xp;
  final int level;
  final int xpIntoLevel;
  final int reviewXp;
  final int practiceXp;

  double get _progress => xpIntoLevel / 100;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DeckoSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 26,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    '$level',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: DeckoSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Level $level',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '$xp XP earned',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: DeckoSpacing.lg),
            ClipRRect(
              borderRadius: BorderRadius.circular(DeckoRadii.pill),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 10,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: DeckoSpacing.sm),
            Row(
              children: <Widget>[
                Flexible(
                  child: Text(
                    '$xpIntoLevel / 100 XP to level ${level + 1}',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: DeckoSpacing.sm),
                Text(
                  'Review $reviewXp · Practice $practiceXp',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.footnote,
  });

  final FaIconData icon;
  final String value;
  final String label;

  /// An optional kind/encouraging line (e.g. streak status).
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DeckoSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            FaIcon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: DeckoSpacing.md),
            Text(
              value,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: DeckoSpacing.xs),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (footnote != null) ...<Widget>[
              const SizedBox(height: DeckoSpacing.xs),
              Text(
                footnote!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}



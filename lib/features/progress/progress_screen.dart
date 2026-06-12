import 'package:flutter/material.dart';

import '../../app/decko_app.dart';
import '../../core/constants/decko_spacing.dart';
import '../../core/widgets/achievement_badge.dart';
import '../../core/widgets/section_header.dart';
import '../../domain/progress_snapshot.dart';
import '../../domain/review_rating.dart';
import '../../domain/review_session_result.dart';

/// Decko's gamification screen, backed by the [ProgressRepository].
///
/// XP, level, streak and "reviewed today" come from stored local progress (no
/// mock values). Before any session it shows a warm empty state rather than
/// pretending there is progress.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  Future<ProgressSnapshot>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= DeckoApp.progressOf(context).getSnapshot();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your progress')),
      body: SafeArea(
        child: FutureBuilder<ProgressSnapshot>(
          future: _future,
          builder: (BuildContext context,
              AsyncSnapshot<ProgressSnapshot> async) {
            if (!async.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final ProgressSnapshot snapshot = async.data!;
            return ListView(
              padding: const EdgeInsets.all(DeckoSpacing.pagePadding),
              children: snapshot.hasProgress
                  ? _progressViews(snapshot)
                  : _emptyViews(),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _progressViews(ProgressSnapshot s) {
    return <Widget>[
      _LevelCard(
        xp: s.totalXp,
        level: s.currentLevel,
        xpIntoLevel: s.xpIntoLevel,
      ),
      const SizedBox(height: DeckoSpacing.lg),
      Row(
        children: <Widget>[
          Expanded(
            child: _StatCard(
              icon: Icons.local_fire_department_rounded,
              value: '${s.currentStreakDays} '
                  '${s.currentStreakDays == 1 ? 'day' : 'days'}',
              label: 'Current streak',
            ),
          ),
          const SizedBox(width: DeckoSpacing.md),
          Expanded(
            child: _StatCard(
              icon: Icons.task_alt_rounded,
              value: '${s.cardsReviewedToday}',
              label: 'Cards reviewed today',
            ),
          ),
        ],
      ),
      if (s.lastSessionResult != null) ...<Widget>[
        const SizedBox(height: DeckoSpacing.xxl),
        const SectionHeader(title: 'Your latest review'),
        const SizedBox(height: DeckoSpacing.md),
        _LatestReviewCard(result: s.lastSessionResult!),
      ],
      const SizedBox(height: DeckoSpacing.xxl),
      const SectionHeader(
        title: 'Achievements',
        subtitle: 'Milestones you’ll unlock as you study.',
      ),
      const SizedBox(height: DeckoSpacing.lg),
      _BadgeRow(snapshot: s),
    ];
  }

  List<Widget> _emptyViews() {
    return <Widget>[
      const _EmptyProgress(),
      const SizedBox(height: DeckoSpacing.xxl),
      const SectionHeader(
        title: 'Achievements',
        subtitle: 'Milestones you’ll unlock as you study.',
      ),
      const SizedBox(height: DeckoSpacing.lg),
      const _BadgeRow(snapshot: ProgressSnapshot.empty),
    ];
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
              child: Icon(
                Icons.rocket_launch_rounded,
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
  });

  final int xp;
  final int level;
  final int xpIntoLevel;

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
            Text(
              '$xpIntoLevel / 100 XP to level ${level + 1}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
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
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DeckoSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: theme.colorScheme.primary),
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
          ],
        ),
      ),
    );
  }
}

class _LatestReviewCard extends StatelessWidget {
  const _LatestReviewCard({required this.result});

  final ReviewSessionResult result;

  static const Map<ReviewRating, Color> _accents = <ReviewRating, Color>{
    ReviewRating.again: Color(0xFFE5534B),
    ReviewRating.hard: Color(0xFFE0883A),
    ReviewRating.good: Color(0xFF3FA66A),
    ReviewRating.easy: Color(0xFF3F77E0),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DeckoSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${result.totalCards} '
              '${result.totalCards == 1 ? 'card' : 'cards'} reviewed',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: DeckoSpacing.md),
            Row(
              children: <Widget>[
                for (final ReviewRating rating in ReviewRating.values)
                  Expanded(
                    child: _RatingCount(
                      label: rating.label,
                      count: result.countFor(rating),
                      accent: _accents[rating]!,
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

class _RatingCount extends StatelessWidget {
  const _RatingCount({
    required this.label,
    required this.count,
    required this.accent,
  });

  final String label;
  final int count;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Text(
          '$count',
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700, color: accent),
        ),
        const SizedBox(height: DeckoSpacing.xs),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _BadgeRow extends StatelessWidget {
  const _BadgeRow({required this.snapshot});

  final ProgressSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final ReviewSessionResult? last = snapshot.lastSessionResult;
    final bool perfectRound = last != null &&
        last.totalCards > 0 &&
        last.againCount == 0 &&
        last.hardCount == 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AchievementBadge(
          icon: Icons.flag_rounded,
          label: 'First Review',
          earned: snapshot.hasProgress,
        ),
        AchievementBadge(
          icon: Icons.workspace_premium_rounded,
          label: 'Perfect Round',
          earned: perfectRound,
        ),
        AchievementBadge(
          icon: Icons.local_fire_department_rounded,
          label: 'Three Day Streak',
          earned: snapshot.currentStreakDays >= 3,
        ),
      ],
    );
  }
}

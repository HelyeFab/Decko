import 'package:flutter/material.dart';

import '../../core/constants/decko_spacing.dart';
import '../../core/widgets/achievement_badge.dart';
import '../../core/widgets/section_header.dart';

/// A preview of Decko's gamification: XP, streak, daily count, level and
/// achievement badges.
///
/// All values are mock data for MVP_001. In later MVPs these derive from
/// recorded `ReviewEvent`s rather than being hard-coded (see the roadmap's
/// gamification stage).
class ProgressPlaceholderScreen extends StatelessWidget {
  const ProgressPlaceholderScreen({super.key});

  // Mock figures from the brief.
  static const int _xp = 120;
  static const int _level = 2;
  static const int _streakDays = 3;
  static const int _reviewedToday = 18;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your progress')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DeckoSpacing.pagePadding),
          children: <Widget>[
            _LevelCard(xp: _xp, level: _level),
            const SizedBox(height: DeckoSpacing.lg),
            Row(
              children: const <Widget>[
                Expanded(
                  child: _StatCard(
                    icon: Icons.local_fire_department_rounded,
                    value: '$_streakDays days',
                    label: 'Current streak',
                  ),
                ),
                SizedBox(width: DeckoSpacing.md),
                Expanded(
                  child: _StatCard(
                    icon: Icons.task_alt_rounded,
                    value: '$_reviewedToday',
                    label: 'Reviewed today',
                  ),
                ),
              ],
            ),
            const SizedBox(height: DeckoSpacing.xxl),
            const SectionHeader(
              title: 'Achievements',
              subtitle: 'Milestones you’ll unlock as you study.',
            ),
            const SizedBox(height: DeckoSpacing.lg),
            const _BadgeRow(),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.xp, required this.level});

  final int xp;
  final int level;

  // Mock progression: 100 XP per level.
  int get _xpIntoLevel => xp % 100;
  double get _progress => _xpIntoLevel / 100;

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
                        '$xp XP total',
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
              '$_xpIntoLevel / 100 XP to level ${level + 1}',
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

class _BadgeRow extends StatelessWidget {
  const _BadgeRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AchievementBadge(
          icon: Icons.flag_rounded,
          label: 'First Review',
          earned: true,
        ),
        AchievementBadge(
          icon: Icons.workspace_premium_rounded,
          label: 'Perfect Round',
          earned: true,
        ),
        AchievementBadge(
          icon: Icons.local_fire_department_rounded,
          label: 'Three Day Streak',
        ),
      ],
    );
  }
}

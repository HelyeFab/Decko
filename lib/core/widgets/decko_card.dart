import 'package:flutter/material.dart';

import '../../app/theme/card_theme_config.dart';
import '../../domain/learning_item.dart';
import '../constants/decko_spacing.dart';

/// Renders a [LearningItem] in one of Decko's card themes.
///
/// This is the reusable surface that both the review screen and the theme
/// gallery share, so a card looks identical wherever it appears. The visual
/// treatment is driven entirely by [CardThemeStyle] — no scheduling or domain
/// logic lives here.
class DeckoCard extends StatelessWidget {
  const DeckoCard({
    super.key,
    required this.item,
    required this.style,
    this.revealed = false,
  });

  final LearningItem item;
  final CardThemeStyle style;

  /// Whether the answer (back/example) is shown.
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    return switch (style) {
      CardThemeStyle.minimal => _MinimalCard(item: item, revealed: revealed),
      CardThemeStyle.detailed => _DetailedCard(item: item, revealed: revealed),
      CardThemeStyle.game => _GameCard(item: item, revealed: revealed),
    };
  }
}

class _MinimalCard extends StatelessWidget {
  const _MinimalCard({required this.item, required this.revealed});

  final LearningItem item;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DeckoSpacing.xl,
          vertical: DeckoSpacing.xxxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              item.front,
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (item.reading != null) ...<Widget>[
              const SizedBox(height: DeckoSpacing.sm),
              Text(
                item.reading!,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (revealed) ...<Widget>[
              const SizedBox(height: DeckoSpacing.xl),
              Divider(color: theme.colorScheme.outlineVariant),
              const SizedBox(height: DeckoSpacing.xl),
              Text(
                item.back,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              if (item.example != null) ...<Widget>[
                const SizedBox(height: DeckoSpacing.md),
                Text(
                  item.example!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailedCard extends StatelessWidget {
  const _DetailedCard({required this.item, required this.revealed});

  final LearningItem item;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DeckoSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    item.front,
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (item.reading != null)
                  Chip(
                    label: Text(item.reading!),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: DeckoSpacing.lg),
            _LabelledRow(
              label: 'Meaning',
              child: Text(
                revealed ? item.back : 'Tap to reveal',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: revealed
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (item.example != null) ...<Widget>[
              const SizedBox(height: DeckoSpacing.md),
              _LabelledRow(
                label: 'Example',
                child: Text(
                  revealed ? item.example! : '—',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ],
            if (item.tags.isNotEmpty) ...<Widget>[
              const SizedBox(height: DeckoSpacing.lg),
              Wrap(
                spacing: DeckoSpacing.sm,
                children: <Widget>[
                  for (final String tag in item.tags)
                    Chip(
                      label: Text('#$tag'),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LabelledRow extends StatelessWidget {
  const _LabelledRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: DeckoSpacing.xs),
        child,
      ],
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.item, required this.revealed});

  final LearningItem item;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DeckoSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DeckoRadii.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[scheme.primary, scheme.tertiary],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.bolt_rounded, color: scheme.onPrimary, size: 20),
              const SizedBox(width: DeckoSpacing.xs),
              Text(
                'CHALLENGE',
                style: textTheme.labelMedium?.copyWith(
                  color: scheme.onPrimary,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: DeckoSpacing.xl),
          Text(
            item.front,
            style: textTheme.displaySmall?.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (item.reading != null) ...<Widget>[
            const SizedBox(height: DeckoSpacing.xs),
            Text(
              item.reading!,
              style: textTheme.titleMedium?.copyWith(
                color: scheme.onPrimary.withValues(alpha: 0.85),
              ),
            ),
          ],
          const SizedBox(height: DeckoSpacing.xl),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DeckoSpacing.lg),
            decoration: BoxDecoration(
              color: scheme.onPrimary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(DeckoRadii.md),
            ),
            child: Text(
              revealed ? item.back : 'Reveal to score XP',
              style: textTheme.titleLarge?.copyWith(
                color: scheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

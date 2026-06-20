import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/constants/decko_spacing.dart';
import '../../../domain/deck.dart';

/// A compact deck row for Home (MVP_008.5).
///
/// Trades the older full-bleed tile for a calmer single line: icon, name,
/// provenance, and a live "to study" badge so the list reads as a scannable
/// shelf rather than a stack of marketing cards. [toStudy] is null while the
/// per-deck count is still loading.
class DeckRow extends StatelessWidget {
  const DeckRow({
    super.key,
    required this.deck,
    required this.toStudy,
    required this.onTap,
  });

  final Deck deck;
  final int? toStudy;
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
                child: FaIcon(FontAwesomeIcons.layerGroup,
                    size: 18, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: DeckoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      deck.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${deck.itemCount} '
                      '${deck.itemCount == 1 ? 'card' : 'cards'}'
                      ' · ${deck.isImported ? 'Imported' : 'Demo'}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DeckoSpacing.sm),
              _ToStudyBadge(count: toStudy),
              const SizedBox(width: DeckoSpacing.sm),
              FaIcon(FontAwesomeIcons.chevronRight,
                  size: 14, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// The trailing count: a filled pill when cards wait, a quiet check when not.
class _ToStudyBadge extends StatelessWidget {
  const _ToStudyBadge({required this.count});

  final int? count;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    if (count == null) {
      return const SizedBox(width: 24, height: 24);
    }
    if (count == 0) {
      return FaIcon(FontAwesomeIcons.check,
          size: 14, color: scheme.onSurfaceVariant);
    }
    return Container(
      constraints: const BoxConstraints(minWidth: 28),
      padding: const EdgeInsets.symmetric(
        horizontal: DeckoSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(DeckoRadii.pill),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: theme.textTheme.labelMedium?.copyWith(
          color: scheme.onPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/constants/decko_spacing.dart';
import '../../../core/constants/decko_strings.dart';

/// The empty-state card shown when a learner has no decks yet.
///
/// Offers the two primary paths into the app: import your own deck, or try the
/// bundled demo deck.
class EmptyLibraryCard extends StatelessWidget {
  const EmptyLibraryCard({
    super.key,
    required this.onImport,
    required this.onDemo,
  });

  final VoidCallback onImport;
  final VoidCallback onDemo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DeckoSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(DeckoSpacing.lg),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(DeckoRadii.md),
              ),
              child: Icon(
                Icons.style_rounded,
                size: 36,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: DeckoSpacing.lg),
            Text(
              DeckoStrings.emptyTitle,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: DeckoSpacing.xs),
            Text(
              DeckoStrings.emptyBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DeckoSpacing.xl),
            FilledButton.icon(
              onPressed: onImport,
              icon: const Icon(Icons.add_rounded),
              label: const Text(DeckoStrings.importCta),
            ),
            const SizedBox(height: DeckoSpacing.md),
            OutlinedButton.icon(
              onPressed: onDemo,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text(DeckoStrings.demoCta),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/constants/decko_spacing.dart';
import '../../core/widgets/section_header.dart';

/// Placeholder for the deck import flow.
///
/// MVP_001 does not parse real files (see the brief's non-goals). Each format
/// is shown as a "Coming soon" option so the product intent is clear without
/// implying support that doesn't exist yet.
class ImportPlaceholderScreen extends StatelessWidget {
  const ImportPlaceholderScreen({super.key});

  static const List<_ImportOption> _options = <_ImportOption>[
    _ImportOption(
      icon: Icons.inventory_2_outlined,
      title: 'Import .apkg deck',
      subtitle: 'Bring an Anki package across, decks and all.',
    ),
    _ImportOption(
      icon: Icons.grid_on_rounded,
      title: 'Import CSV',
      subtitle: 'A simple spreadsheet of fronts and backs.',
    ),
    _ImportOption(
      icon: Icons.data_object_rounded,
      title: 'Import JSON',
      subtitle: 'Decko’s own structured deck format.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Import a deck')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DeckoSpacing.pagePadding),
          children: <Widget>[
            const SectionHeader(
              title: 'Bring your own cards',
              subtitle:
                  'Decko will turn your existing decks into beautiful, FSRS-ready study sessions.',
            ),
            const SizedBox(height: DeckoSpacing.xl),
            for (final _ImportOption option in _options) ...<Widget>[
              _ImportOptionCard(option: option),
              const SizedBox(height: DeckoSpacing.md),
            ],
            const SizedBox(height: DeckoSpacing.sm),
            Container(
              padding: const EdgeInsets.all(DeckoSpacing.lg),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(DeckoRadii.md),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.info_outline_rounded,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: DeckoSpacing.md),
                  Expanded(
                    child: Text(
                      'Importing isn’t wired up yet — these are previews of what’s coming.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportOption {
  const _ImportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

class _ImportOptionCard extends StatelessWidget {
  const _ImportOptionCard({required this.option});

  final _ImportOption option;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: 0.65,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(DeckoSpacing.lg),
          child: Row(
            children: <Widget>[
              Icon(option.icon, size: 28, color: theme.colorScheme.primary),
              const SizedBox(width: DeckoSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      option.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: DeckoSpacing.xs),
                    Text(
                      option.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DeckoSpacing.md),
              Chip(
                label: const Text('Coming soon'),
                visualDensity: VisualDensity.compact,
                backgroundColor: theme.colorScheme.secondaryContainer,
                labelStyle: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

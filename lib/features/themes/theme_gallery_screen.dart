import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../app/decko_app.dart';
import '../../app/theme/app_theme_config.dart';
import '../../app/theme/card_theme_config.dart';
import '../../app/theme/theme_controller.dart';
import '../../app/theme/theme_registry.dart';
import '../../core/widgets/decko_app_bar.dart';
import '../../core/constants/decko_spacing.dart';
import '../../core/widgets/decko_card.dart';
import '../../core/widgets/section_header.dart';
import '../../data/mock_decks.dart';

/// Lets the learner preview Decko's two theme layers: app themes (the shell)
/// and card themes (the flashcard), kept separate per DEC-004.
///
/// Selecting an app theme updates the whole app live via the [ThemeController].
/// Card themes are preview-only for MVP_001.
class ThemeGalleryScreen extends StatelessWidget {
  const ThemeGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController controller = DeckoApp.themeOf(context);

    return Scaffold(
      appBar: const DeckoAppBar(title: 'Theme gallery'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DeckoSpacing.pagePadding),
          children: <Widget>[
            const SectionHeader(
              title: 'App themes',
              subtitle: 'Style the whole app. Tap to apply instantly.',
            ),
            const SizedBox(height: DeckoSpacing.lg),
            ValueListenableBuilder<AppThemeConfig>(
              valueListenable: controller,
              builder: (BuildContext context, AppThemeConfig selected, _) {
                return Column(
                  children: <Widget>[
                    for (final AppThemeConfig t in ThemeRegistry.appThemes)
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: DeckoSpacing.md),
                        child: _AppThemeTile(
                          config: t,
                          selected: t.id == selected.id,
                          onTap: () => controller.select(t),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: DeckoSpacing.xl),
            const SectionHeader(
              title: 'Card themes',
              subtitle: 'Style the flashcard itself. Same card, three looks.',
            ),
            const SizedBox(height: DeckoSpacing.lg),
            for (final CardThemeConfig card in ThemeRegistry.cardThemes) ...<Widget>[
              _CardThemePreview(config: card),
              const SizedBox(height: DeckoSpacing.xl),
            ],
          ],
        ),
      ),
    );
  }
}

class _AppThemeTile extends StatelessWidget {
  const _AppThemeTile({
    required this.config,
    required this.selected,
    required this.onTap,
  });

  final AppThemeConfig config;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(DeckoRadii.lg),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(DeckoSpacing.lg),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(DeckoRadii.lg),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              _SwatchCluster(config: config),
              const SizedBox(width: DeckoSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      config.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: DeckoSpacing.xs),
                    Text(
                      config.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              FaIcon(
                selected
                    ? FontAwesomeIcons.circleCheck
                    : FontAwesomeIcons.circle,
                color: selected ? scheme.primary : scheme.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A trio of colour swatches sampled from a theme so its palette previews even
/// while a different theme is active.
class _SwatchCluster extends StatelessWidget {
  const _SwatchCluster({required this.config});

  final AppThemeConfig config;

  @override
  Widget build(BuildContext context) {
    final ColorScheme s = config.colors;
    final List<Color> colours = <Color>[s.primary, s.secondary, s.surface];
    return Container(
      padding: const EdgeInsets.all(DeckoSpacing.xs),
      decoration: BoxDecoration(
        color: config.themeData.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(DeckoRadii.sm),
        border: Border.all(color: s.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final Color c in colours)
            Container(
              height: 28,
              width: 14,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      ),
    );
  }
}

class _CardThemePreview extends StatelessWidget {
  const _CardThemePreview({required this.config});

  final CardThemeConfig config;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              config.name,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: DeckoSpacing.sm),
            Expanded(
              child: Text(
                config.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: DeckoSpacing.md),
        DeckoCard(
          item: MockDecks.sampleCard,
          deckId: MockDecks.demoJapanese.id,
          style: config.style,
          revealed: true,
        ),
      ],
    );
  }
}

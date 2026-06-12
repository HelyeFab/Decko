import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/decko_router.dart';
import '../../core/constants/decko_spacing.dart';
import '../../core/constants/decko_strings.dart';
import '../../core/widgets/promise_tile.dart';
import '../../core/widgets/section_header.dart';
import 'widgets/empty_library_card.dart';

/// Decko's home: the deck library.
///
/// For MVP_001 the library is empty, so this leads with branding, the product
/// promise and the two entry points (import / demo). Theme gallery and progress
/// are reachable from the app bar.
class DeckLibraryScreen extends StatelessWidget {
  const DeckLibraryScreen({super.key});

  static const List<IconData> _promiseIcons = <IconData>[
    Icons.schedule_rounded,
    Icons.palette_rounded,
    Icons.local_fire_department_rounded,
    Icons.extension_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: DeckoSpacing.pagePadding,
        title: Text(
          DeckoStrings.wordmark,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.primary,
            letterSpacing: -0.5,
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Theme gallery',
            icon: const Icon(Icons.palette_outlined),
            onPressed: () => context.push(DeckoRoutes.themes),
          ),
          IconButton(
            tooltip: 'Progress',
            icon: const Icon(Icons.insights_rounded),
            onPressed: () => context.push(DeckoRoutes.progress),
          ),
          const SizedBox(width: DeckoSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            DeckoSpacing.pagePadding,
            DeckoSpacing.sm,
            DeckoSpacing.pagePadding,
            DeckoSpacing.xxxl,
          ),
          children: <Widget>[
            Text(
              DeckoStrings.tagline,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
            const SizedBox(height: DeckoSpacing.xl),
            EmptyLibraryCard(
              onImport: () => context.push(DeckoRoutes.import),
              onDemo: () => context.push(DeckoRoutes.review),
            ),
            const SizedBox(height: DeckoSpacing.xxl),
            const SectionHeader(
              title: 'Why you’ll love Decko',
              subtitle: 'Everything coming to your study sessions.',
            ),
            const SizedBox(height: DeckoSpacing.lg),
            _PromiseGrid(icons: _promiseIcons),
          ],
        ),
      ),
    );
  }
}

class _PromiseGrid extends StatelessWidget {
  const _PromiseGrid({required this.icons});

  final List<IconData> icons;

  @override
  Widget build(BuildContext context) {
    final List<(String, String)> promises = DeckoStrings.promises;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: promises.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: DeckoSpacing.md,
        crossAxisSpacing: DeckoSpacing.md,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (BuildContext context, int index) {
        final (String title, String blurb) = promises[index];
        return PromiseTile(
          icon: icons[index % icons.length],
          title: title,
          blurb: blurb,
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../app/decko_app.dart';
import '../../core/constants/decko_spacing.dart';
import '../../core/widgets/decko_app_bar.dart';
import '../../domain/deck.dart';
import '../../domain/import/deck_import_info.dart';
import 'widgets/import_health_summary.dart';

/// The saved import report for an imported deck (MVP_014). Reached from deck
/// detail; shows the same calm health summary the user saw at import time.
class ImportReportScreen extends StatelessWidget {
  const ImportReportScreen({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context) {
    final Deck? deck = DeckoApp.repositoryOf(context).getDeckById(deckId);
    final DeckImportInfo? info = deck?.importInfo;

    return Scaffold(
      appBar: const DeckoAppBar(title: 'Import report'),
      body: SafeArea(
        child: info?.diagnostics == null
            ? const _NoReport()
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  DeckoSpacing.pagePadding,
                  DeckoSpacing.lg,
                  DeckoSpacing.pagePadding,
                  DeckoSpacing.xxxl,
                ),
                children: <Widget>[
                  Text(
                    deck!.name,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: DeckoSpacing.lg),
                  ImportHealthSummary(diagnostics: info!.diagnostics!),
                ],
              ),
      ),
    );
  }
}

class _NoReport extends StatelessWidget {
  const _NoReport();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DeckoSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FaIcon(FontAwesomeIcons.fileCircleQuestion,
                size: 44, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: DeckoSpacing.lg),
            Text(
              'No import report',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: DeckoSpacing.sm),
            Text(
              'This deck was imported before Decko started saving import '
              'reports. Re-import it to see one.',
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

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../app/deck_store.dart';
import '../../app/decko_app.dart';
import '../../app/decko_router.dart';
import '../../core/constants/decko_spacing.dart';
import '../../core/widgets/decko_app_bar.dart';
import '../../core/widgets/decko_snackbar.dart';
import '../../core/widgets/section_header.dart';
import '../../data/import/anki_apkg_import_adapter.dart';
import '../../domain/deck.dart';
import '../../domain/import/deck_import_adapter.dart';
import '../../domain/import/deck_import_preview.dart';
import '../../domain/import/import_diagnostics.dart';
import '../../domain/learning_item.dart';
import '../../domain/repositories/review_state_repository.dart';
import '../../domain/review_card_state.dart';
import 'widgets/import_health_summary.dart';
import 'widgets/import_preview_panel.dart';

/// Picks the bytes of an `.apkg` file, or null if cancelled.
typedef ApkgPicker = Future<Uint8List?> Function();

enum _Phase { idle, analysing, preview, importing, result, error }

/// The Anki import flow as a single screen with internal phases.
///
/// Parsing lives entirely in the [DeckImportAdapter] (DEC-010); this screen only
/// orchestrates pick → preview → choose → persist. The adapter and file picker
/// are injectable so the flow is testable without the platform file picker.
class ImportScreen extends StatefulWidget {
  const ImportScreen({
    super.key,
    this.adapter = const AnkiApkgImportAdapter(),
    this.picker,
  });

  final DeckImportAdapter adapter;
  final ApkgPicker? picker;

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  _Phase _phase = _Phase.idle;
  Uint8List? _bytes;
  DeckImportPreview? _preview;
  Deck? _importedDeck;
  String _error = '';

  Future<void> _pickAndPreview() async {
    setState(() => _phase = _Phase.analysing);
    try {
      final ApkgPicker pick = widget.picker ?? _defaultPicker;
      final Uint8List? bytes = await pick();
      if (bytes == null) {
        if (mounted) setState(() => _phase = _Phase.idle); // cancelled
        return;
      }
      final DeckImportPreview preview = await widget.adapter.preview(bytes);
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _preview = preview;
        _phase = _Phase.preview;
      });
    } on DeckImportException catch (e) {
      _fail(e.message);
    } catch (_) {
      _fail('Decko couldn’t read this deck. Please try a different file.');
    }
  }

  Future<void> _confirm({required bool keepProgress}) async {
    final Uint8List? bytes = _bytes;
    if (bytes == null) return;
    setState(() => _phase = _Phase.importing);

    final DeckStore store = DeckoApp.deckStoreOf(context);
    final ReviewStateRepository reviewState = DeckoApp.reviewStateOf(context);
    try {
      final Deck deck = await widget.adapter.importDeck(
        bytes,
        keepProgress: keepProgress,
        importedAt: DateTime.now(),
        mediaStore: DeckoApp.mediaOf(context),
        sourceStore: DeckoApp.sourceOf(context),
      );
      await store.addImportedDeck(deck);
      // Seed per-card review state (keeps imported Anki progress, or starts new).
      await reviewState.saveStates(<ReviewCardState>[
        for (final LearningItem item in deck.items)
          ReviewCardState.fromLearningItem(deck.id, item),
      ]);
      if (!mounted) return;
      // Clean imports stay frictionless (snackbar → Home). Imports with notes
      // pause on a calm result so nothing's a surprise (MVP_014).
      final ImportHealth? health = deck.importInfo?.diagnostics?.health;
      if (health == ImportHealth.usableWithWarnings) {
        setState(() {
          _importedDeck = deck;
          _bytes = null;
          _preview = null;
          _phase = _Phase.result;
        });
      } else {
        setState(() {
          _phase = _Phase.idle;
          _bytes = null;
          _preview = null;
        });
        DeckoSnackbar.showSuccess(context, 'Imported “${deck.name}”.');
        GoRouter.of(context).go(DeckoRoutes.home);
      }
    } on DeckImportException catch (e) {
      _fail(e.message);
    } catch (_) {
      _fail('Something went wrong while importing. Please try again.');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _phase = _Phase.error;
    });
  }

  void _reset() => setState(() => _phase = _Phase.idle);

  void _finishResult() {
    if (!mounted) return;
    setState(() {
      _phase = _Phase.idle;
      _importedDeck = null;
    });
    GoRouter.of(context).go(DeckoRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DeckoAppBar(title: 'Import a deck'),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    switch (_phase) {
      case _Phase.analysing:
      case _Phase.importing:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const CircularProgressIndicator(),
              const SizedBox(height: DeckoSpacing.lg),
              Text(_phase == _Phase.analysing
                  ? 'Analysing your deck…'
                  : 'Importing…'),
            ],
          ),
        );
      case _Phase.preview:
        return ImportPreviewPanel(
          preview: _preview!,
          onKeepProgress: () => _confirm(keepProgress: true),
          onStartFresh: () => _confirm(keepProgress: false),
          onCancel: _reset,
        );
      case _Phase.result:
        return _ResultPanel(deck: _importedDeck!, onDone: _finishResult);
      case _Phase.error:
        return _ErrorState(message: _error, onRetry: _reset);
      case _Phase.idle:
        return _IdleOptions(onPickApkg: _pickAndPreview);
    }
  }

  Future<Uint8List?> _defaultPicker() async {
    // NOTE: iOS greys out files whose extension has no system UTI — so we can't
    // filter by `allowedExtensions: ['apkg']`. Pick anything, validate here.
    final FilePickerResult? result =
        await FilePicker.pickFiles(type: FileType.any);
    if (result == null || result.files.isEmpty) return null;
    final PlatformFile file = result.files.first;

    if (!file.name.toLowerCase().endsWith('.apkg')) {
      throw const DeckImportException(
        'Please choose an .apkg file exported from Anki.',
      );
    }

    // Prefer the on-disk path (avoids loading large decks into memory twice).
    final String? path = file.path;
    if (path != null) return File(path).readAsBytesSync();
    if (file.bytes != null) return file.bytes;
    return null;
  }
}

class _IdleOptions extends StatelessWidget {
  const _IdleOptions({required this.onPickApkg});

  final VoidCallback onPickApkg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(DeckoSpacing.pagePadding),
      children: <Widget>[
        const SectionHeader(
          title: 'Bring your own cards',
          subtitle:
              'First import support for Anki. Some complex decks may not import perfectly yet.',
        ),
        const SizedBox(height: DeckoSpacing.xl),
        Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(DeckoRadii.lg),
            onTap: onPickApkg,
            child: Padding(
              padding: const EdgeInsets.all(DeckoSpacing.lg),
              child: Row(
                children: <Widget>[
                  FaIcon(FontAwesomeIcons.boxArchive,
                      size: 28, color: theme.colorScheme.primary),
                  const SizedBox(width: DeckoSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Import Anki deck (.apkg)',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: DeckoSpacing.xs),
                        Text(
                          'Choose an .apkg file to import its cards.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const FaIcon(FontAwesomeIcons.chevronRight),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: DeckoSpacing.md),
        for (final String label in const <String>['Import CSV', 'Import JSON'])
          Padding(
            padding: const EdgeInsets.only(bottom: DeckoSpacing.md),
            child: _ComingSoonOption(label: label),
          ),
        const SizedBox(height: DeckoSpacing.sm),
        Container(
          padding: const EdgeInsets.all(DeckoSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(DeckoRadii.md),
          ),
          child: Row(
            children: <Widget>[
              FaIcon(FontAwesomeIcons.circleInfo,
                  color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: DeckoSpacing.md),
              Expanded(
                child: Text(
                  'Decko imports a copy of your deck — it doesn’t sync with Anki. '
                  'Export with “Support older Anki versions” for best results.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ComingSoonOption extends StatelessWidget {
  const _ComingSoonOption({required this.label});

  final String label;

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
              FaIcon(FontAwesomeIcons.fileLines,
                  size: 28, color: theme.colorScheme.primary),
              const SizedBox(width: DeckoSpacing.lg),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DeckoSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FaIcon(FontAwesomeIcons.circleExclamation,
                size: 56, color: theme.colorScheme.error),
            const SizedBox(height: DeckoSpacing.lg),
            Text(
              'Couldn’t import that deck',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: DeckoSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DeckoSpacing.xl),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

/// Calm post-import result for decks that imported with notes (MVP_014).
class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.deck, required this.onDone});

  final Deck deck;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ImportDiagnostics? diag = deck.importInfo?.diagnostics;
    return ListView(
      padding: const EdgeInsets.all(DeckoSpacing.pagePadding),
      children: <Widget>[
        Text(
          'Imported',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: DeckoSpacing.xs),
        Text(
          deck.name,
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: DeckoSpacing.lg),
        if (diag != null) ImportHealthSummary(diagnostics: diag),
        const SizedBox(height: DeckoSpacing.xl),
        FilledButton.icon(
          onPressed: onDone,
          icon: const FaIcon(FontAwesomeIcons.check),
          label: const Text('Done — start studying'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../app/decko_app.dart';
import '../../core/constants/decko_spacing.dart';
import '../../core/widgets/decko_app_bar.dart';
import '../../core/widgets/section_header.dart';
import '../../domain/import/source/imported_anki_source.dart';

/// Inspect the lossless Anki source preserved for an imported deck (MVP_009).
///
/// Proves that import kept the rich note data — every named field (with its
/// plain value + media refs), tags, note-type field/template definitions, and
/// the per-template card breakdown — even though the review card only renders a
/// simplified subset. Decko-styled, not a raw debug table (DEC-016).
class ImportedSourceScreen extends StatefulWidget {
  const ImportedSourceScreen({
    super.key,
    required this.deckId,
    required this.deckName,
  });

  final String deckId;
  final String deckName;

  @override
  State<ImportedSourceScreen> createState() => _ImportedSourceScreenState();
}

class _ImportedSourceScreenState extends State<ImportedSourceScreen> {
  Future<ImportedAnkiSource?>? _source;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _source ??= DeckoApp.sourceOf(context).getSourceForDeck(widget.deckId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DeckoAppBar(title: 'Imported source'),
      body: SafeArea(
        child: FutureBuilder<ImportedAnkiSource?>(
          future: _source,
          builder: (BuildContext context,
              AsyncSnapshot<ImportedAnkiSource?> snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final ImportedAnkiSource? source = snap.data;
            if (source == null || source.notes.isEmpty) {
              return const _NoSource();
            }
            return _SourceBody(deckName: widget.deckName, source: source);
          },
        ),
      ),
    );
  }
}

class _NoSource extends StatelessWidget {
  const _NoSource();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DeckoSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FaIcon(FontAwesomeIcons.boxOpen,
                size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: DeckoSpacing.lg),
            Text(
              'No preserved source',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: DeckoSpacing.sm),
            Text(
              'This deck was added before Decko began preserving the original '
              'Anki note data, or it isn’t an Anki import. Re-import it to keep '
              'its full source.',
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

class _SourceBody extends StatelessWidget {
  const _SourceBody({required this.deckName, required this.source});

  final String deckName;
  final ImportedAnkiSource source;

  @override
  Widget build(BuildContext context) {
    final ImportedAnkiNote sample = source.notes.first;

    // Card count per template name, to show that templates like
    // Listening / Reading / Production are kept distinct (not collapsed).
    final Map<String, int> perTemplate = <String, int>{};
    for (final ImportedAnkiCardSource c in source.cardSources) {
      final String key = c.templateName ?? 'Card ${c.templateOrdinal + 1}';
      perTemplate[key] = (perTemplate[key] ?? 0) + 1;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DeckoSpacing.pagePadding,
        DeckoSpacing.lg,
        DeckoSpacing.pagePadding,
        DeckoSpacing.xxxl,
      ),
      children: <Widget>[
        _SummaryCard(
          deckName: deckName,
          notes: source.notes.length,
          noteTypes: source.models.length,
          cards: source.cardSources.length,
        ),
        const SizedBox(height: DeckoSpacing.xl),
        const SectionHeader(
          title: 'Note types',
          subtitle: 'Fields and card templates preserved from Anki.',
        ),
        const SizedBox(height: DeckoSpacing.md),
        for (final ImportedAnkiModel m in source.models) ...<Widget>[
          _ModelCard(model: m),
          const SizedBox(height: DeckoSpacing.md),
        ],
        if (perTemplate.isNotEmpty) ...<Widget>[
          const SizedBox(height: DeckoSpacing.sm),
          const SectionHeader(
            title: 'Cards by template',
            subtitle: 'Each note’s cards keep their template identity.',
          ),
          const SizedBox(height: DeckoSpacing.md),
          _ChipsCard(
            chips: <Widget>[
              for (final MapEntry<String, int> e in perTemplate.entries)
                _CountChip(label: e.key, count: e.value),
            ],
          ),
        ],
        const SizedBox(height: DeckoSpacing.xl),
        SectionHeader(
          title: 'Sample note',
          subtitle: source.notes.length == 1
              ? 'The note’s preserved fields.'
              : 'Fields of 1 of ${source.notes.length} preserved notes.',
        ),
        const SizedBox(height: DeckoSpacing.md),
        _NoteCard(note: sample),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.deckName,
    required this.notes,
    required this.noteTypes,
    required this.cards,
  });

  final String deckName;
  final int notes;
  final int noteTypes;
  final int cards;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(DeckoSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(DeckoRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              FaIcon(FontAwesomeIcons.solidCircleCheck,
                  size: 18, color: scheme.onPrimaryContainer),
              const SizedBox(width: DeckoSpacing.sm),
              Expanded(
                child: Text(
                  'Original Anki source preserved',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DeckoSpacing.md),
          Row(
            children: <Widget>[
              _Stat(value: '$notes', label: notes == 1 ? 'note' : 'notes'),
              _Stat(
                  value: '$noteTypes',
                  label: noteTypes == 1 ? 'note type' : 'note types'),
              _Stat(value: '$cards', label: cards == 1 ? 'card' : 'cards'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color fg = theme.colorScheme.onPrimaryContainer;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: theme.textTheme.headlineSmall
                ?.copyWith(color: fg, fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: fg.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  const _ModelCard({required this.model});

  final ImportedAnkiModel model;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(DeckoSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(DeckoRadii.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            model.name,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: DeckoSpacing.md),
          _MiniLabel(text: 'FIELDS (${model.fieldNames.length})'),
          const SizedBox(height: DeckoSpacing.sm),
          Wrap(
            spacing: DeckoSpacing.sm,
            runSpacing: DeckoSpacing.sm,
            children: <Widget>[
              for (final String f in model.fieldNames) _PlainChip(label: f),
            ],
          ),
          if (model.templates.isNotEmpty) ...<Widget>[
            const SizedBox(height: DeckoSpacing.md),
            _MiniLabel(text: 'CARD TEMPLATES (${model.templates.length})'),
            const SizedBox(height: DeckoSpacing.sm),
            Wrap(
              spacing: DeckoSpacing.sm,
              runSpacing: DeckoSpacing.sm,
              children: <Widget>[
                for (final ImportedAnkiCardTemplate t in model.templates)
                  _PlainChip(label: '${t.ordinal + 1}. ${t.name}'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});

  final ImportedAnkiNote note;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(DeckoSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(DeckoRadii.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < note.fields.length; i++) ...<Widget>[
            _FieldRow(field: note.fields[i]),
            if (i != note.fields.length - 1)
              Divider(height: DeckoSpacing.xl, color: scheme.outlineVariant),
          ],
          if (note.tags.isNotEmpty) ...<Widget>[
            Divider(height: DeckoSpacing.xl, color: scheme.outlineVariant),
            _MiniLabel(text: 'TAGS (${note.tags.length})'),
            const SizedBox(height: DeckoSpacing.sm),
            Wrap(
              spacing: DeckoSpacing.sm,
              runSpacing: DeckoSpacing.sm,
              children: <Widget>[
                for (final String t in note.tags) _PlainChip(label: t),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.field});

  final ImportedAnkiField field;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String value =
        field.plainTextValue.trim().isEmpty ? '—' : field.plainTextValue.trim();
    final int audio = field.mediaReferences
        .where((MediaReference r) => r.kind == MediaKind.audio)
        .length;
    final int image = field.mediaReferences
        .where((MediaReference r) => r.kind == MediaKind.image)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            _MiniLabel(text: field.name.toUpperCase()),
            const Spacer(),
            if (audio > 0) _MediaPip(icon: FontAwesomeIcons.volumeHigh, count: audio),
            if (image > 0) ...<Widget>[
              const SizedBox(width: DeckoSpacing.xs),
              _MediaPip(icon: FontAwesomeIcons.image, count: image),
            ],
          ],
        ),
        const SizedBox(height: DeckoSpacing.xs),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: value == '—' ? scheme.onSurfaceVariant : scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _ChipsCard extends StatelessWidget {
  const _ChipsCard({required this.chips});

  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(DeckoSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(DeckoRadii.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Wrap(
        spacing: DeckoSpacing.sm,
        runSpacing: DeckoSpacing.sm,
        children: chips,
      ),
    );
  }
}

class _MiniLabel extends StatelessWidget {
  const _MiniLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.primary,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _PlainChip extends StatelessWidget {
  const _PlainChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DeckoSpacing.md,
        vertical: DeckoSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(DeckoRadii.pill),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DeckoSpacing.md,
        vertical: DeckoSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(DeckoRadii.pill),
      ),
      child: Text(
        '$label · $count',
        style: theme.textTheme.labelMedium?.copyWith(
          color: scheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MediaPip extends StatelessWidget {
  const _MediaPip({required this.icon, required this.count});

  final FaIconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FaIcon(icon, size: 11, color: scheme.onSurfaceVariant),
        const SizedBox(width: 2),
        Text(
          '$count',
          style: theme.textTheme.labelSmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

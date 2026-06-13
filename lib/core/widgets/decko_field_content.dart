import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../app/decko_app.dart';
import '../constants/decko_spacing.dart';
import '../content/anki_content.dart';
import 'furigana_text.dart';

/// Renders an Anki card field that may mix text (with furigana), `[sound:…]`
/// audio, and `<img src=…>` images. Text reuses [FuriganaText]; audio becomes a
/// play button; images render from local files. Media is resolved per-deck via
/// the [MediaStore] in the app scope; missing media degrades gracefully.
class DeckoFieldContent extends StatelessWidget {
  const DeckoFieldContent(
    this.field, {
    super.key,
    required this.deckId,
    this.showFurigana = true,
    this.baseStyle,
    this.align = TextAlign.start,
  });

  final String field;
  final String deckId;
  final bool showFurigana;
  final TextStyle? baseStyle;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final List<AnkiSegment> segments = parseAnkiContent(field);
    final List<Widget> blocks = <Widget>[];
    final List<Widget> inline = <Widget>[];

    void flush() {
      if (inline.isEmpty) return;
      blocks.add(Wrap(
        alignment:
            align == TextAlign.center ? WrapAlignment.center : WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: DeckoSpacing.sm,
        runSpacing: DeckoSpacing.xs,
        children: List<Widget>.of(inline),
      ));
      inline.clear();
    }

    for (final AnkiSegment seg in segments) {
      switch (seg) {
        case TextSegment(:final String text):
          inline.add(FuriganaText(
            text,
            showReadings: showFurigana,
            align: align,
            baseStyle: baseStyle,
          ));
        case AudioSegment(:final String fileName):
          inline.add(_AudioButton(deckId: deckId, fileName: fileName));
        case ImageSegment(:final String fileName):
          flush();
          blocks.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: DeckoSpacing.sm),
            child: _MediaImage(deckId: deckId, fileName: fileName),
          ));
      }
    }
    flush();

    if (blocks.isEmpty) return const SizedBox.shrink();
    if (blocks.length == 1) return blocks.first;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          align == TextAlign.center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: <Widget>[
        for (final Widget b in blocks) ...<Widget>[
          b,
          const SizedBox(height: DeckoSpacing.sm),
        ],
      ],
    );
  }
}

class _AudioButton extends StatefulWidget {
  const _AudioButton({required this.deckId, required this.fileName});

  final String deckId;
  final String fileName;

  @override
  State<_AudioButton> createState() => _AudioButtonState();
}

class _AudioButtonState extends State<_AudioButton> {
  final AudioPlayer _player = AudioPlayer();
  bool _unavailable = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    final String? path = await DeckoApp.mediaOf(context)
        .resolveMedia(widget.deckId, widget.fileName);
    if (!mounted) return;
    if (path == null) {
      setState(() => _unavailable = true);
      return;
    }
    try {
      await _player.stop();
      await _player.play(DeviceFileSource(path));
    } catch (_) {
      if (mounted) setState(() => _unavailable = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton.filledTonal(
      tooltip: _unavailable ? 'Audio unavailable' : 'Play audio',
      visualDensity: VisualDensity.compact,
      onPressed: _unavailable ? null : _play,
      icon: FaIcon(
        _unavailable ? FontAwesomeIcons.volumeXmark : FontAwesomeIcons.volumeHigh,
        color: _unavailable ? scheme.onSurfaceVariant : null,
      ),
    );
  }
}

class _MediaImage extends StatelessWidget {
  const _MediaImage({required this.deckId, required this.fileName});

  final String deckId;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: DeckoApp.mediaOf(context).resolveMedia(deckId, fileName),
      builder: (BuildContext context, AsyncSnapshot<String?> snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox(height: 40);
        }
        final String? path = snap.data;
        if (path == null) return const _ImagePlaceholder();
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DeckoRadii.md),
            child: Image.file(
              File(path),
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const _ImagePlaceholder(),
            ),
          ),
        );
      },
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(DeckoRadii.md),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          FaIcon(FontAwesomeIcons.image, color: scheme.onSurfaceVariant),
          const SizedBox(height: DeckoSpacing.xs),
          Text('Image unavailable',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }
}

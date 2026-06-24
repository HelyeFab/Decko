import 'package:flutter/material.dart';

import '../../../core/constants/decko_spacing.dart';
import '../../../core/content/anki_content.dart';
import '../../../core/widgets/furigana_text.dart';
import '../../../domain/learning_item.dart';

/// A single-line preview of a [LearningItem] in the deck detail list.
class SampleItemRow extends StatelessWidget {
  const SampleItemRow({super.key, required this.item});

  final LearningItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Most decks: expression on the front, meaning on the back. But some note
    // types (e.g. listening cards) have a media-only front and pack the
    // "expression\nmeaning" into the back — without this, the front column is
    // blank and the row collapses to the right. Fall back to the back's lines.
    final String frontText = stripMedia(item.front).trim();
    final String leftBase;
    final String rightText;
    if (frontText.isNotEmpty) {
      leftBase = item.front;
      rightText = item.back;
    } else {
      final List<String> lines = item.back.split('\n');
      leftBase = lines.first.trim();
      rightText =
          lines.length > 1 ? lines.sublist(1).join(' ').trim() : '';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DeckoSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                FuriganaText(
                  stripMedia(leftBase), // compact base text, no media markers
                  showReadings: false,
                  baseStyle: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (item.reading != null)
                  Text(
                    item.reading!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: DeckoSpacing.md),
          Flexible(
            child: Text(
              rightText,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

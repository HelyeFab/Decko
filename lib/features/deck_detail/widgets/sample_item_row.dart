import 'package:flutter/material.dart';

import '../../../core/constants/decko_spacing.dart';
import '../../../core/widgets/furigana_text.dart';
import '../../../domain/learning_item.dart';

/// A single-line preview of a [LearningItem] in the deck detail list.
class SampleItemRow extends StatelessWidget {
  const SampleItemRow({super.key, required this.item});

  final LearningItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  item.front,
                  showReadings: false, // compact base text in the list
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
              item.back,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

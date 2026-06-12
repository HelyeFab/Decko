import 'package:flutter/material.dart';

import '../../app/theme/card_theme_config.dart';
import '../../core/constants/decko_spacing.dart';
import '../../core/widgets/decko_card.dart';
import '../../data/mock_decks.dart';
import '../../domain/learning_item.dart';
import '../../domain/review_rating.dart';
import 'widgets/rating_button_row.dart';

/// A preview of the review experience.
///
/// Demonstrates the card surface, the reveal interaction and the grading row.
/// Grading does not schedule anything yet — it simply acknowledges the tap and
/// resets, ready for a real `SchedulerService` later (DEC-003).
class ReviewPlaceholderScreen extends StatefulWidget {
  const ReviewPlaceholderScreen({super.key});

  @override
  State<ReviewPlaceholderScreen> createState() =>
      _ReviewPlaceholderScreenState();
}

class _ReviewPlaceholderScreenState extends State<ReviewPlaceholderScreen> {
  final LearningItem _item = MockDecks.sampleCard;
  bool _revealed = false;
  CardThemeStyle _cardStyle = CardThemeStyle.minimal;

  void _reveal() => setState(() => _revealed = true);

  void _rate(ReviewRating rating) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Recorded “${rating.label}” — scheduling comes later.'),
          duration: const Duration(milliseconds: 1400),
        ),
      );
    setState(() => _revealed = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review preview'),
        actions: <Widget>[
          PopupMenuButton<CardThemeStyle>(
            tooltip: 'Card theme',
            icon: const Icon(Icons.style_outlined),
            initialValue: _cardStyle,
            onSelected: (CardThemeStyle style) =>
                setState(() => _cardStyle = style),
            itemBuilder: (BuildContext context) =>
                const <PopupMenuEntry<CardThemeStyle>>[
              PopupMenuItem<CardThemeStyle>(
                value: CardThemeStyle.minimal,
                child: Text('Minimal Card'),
              ),
              PopupMenuItem<CardThemeStyle>(
                value: CardThemeStyle.detailed,
                child: Text('Detailed Card'),
              ),
              PopupMenuItem<CardThemeStyle>(
                value: CardThemeStyle.game,
                child: Text('Game Card'),
              ),
            ],
          ),
          const SizedBox(width: DeckoSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DeckoSpacing.pagePadding),
          child: Column(
            children: <Widget>[
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: DeckoCard(
                      item: _item,
                      style: _cardStyle,
                      revealed: _revealed,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: DeckoSpacing.lg),
              if (!_revealed)
                FilledButton.icon(
                  onPressed: _reveal,
                  icon: const Icon(Icons.visibility_rounded),
                  label: const Text('Show answer'),
                )
              else ...<Widget>[
                Text(
                  'How well did you know it?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: DeckoSpacing.md),
                RatingButtonRow(onRate: _rate),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

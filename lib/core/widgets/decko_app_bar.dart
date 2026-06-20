import 'package:flutter/material.dart';

import '../constants/decko_spacing.dart';
import '../constants/decko_strings.dart';

/// Decko's shared app-bar pattern, so every screen wears the same chrome.
///
/// Two registers: the [DeckoAppBar.wordmark] constructor stamps the Decko
/// wordmark (used on Home), while the default constructor shows a screen
/// [title]. Either way the spacing, weight, and colour come from one place so
/// the shell never drifts back to stock Material (MVP_008.5, DEC-017).
class DeckoAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DeckoAppBar({
    super.key,
    required this.title,
    this.actions,
  }) : _wordmark = false;

  const DeckoAppBar.wordmark({
    super.key,
    this.actions,
  })  : title = DeckoStrings.wordmark,
        _wordmark = true;

  /// The text shown at the leading edge of the bar.
  final String title;

  /// Trailing actions; kept to a small, relevant set per screen.
  final List<Widget>? actions;

  final bool _wordmark;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? style = _wordmark
        ? theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.primary,
            letterSpacing: -0.5,
          )
        : theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          );

    return AppBar(
      titleSpacing: DeckoSpacing.pagePadding,
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      title: Text(title, style: style),
      actions: <Widget>[
        ...?actions,
        const SizedBox(width: DeckoSpacing.sm),
      ],
    );
  }
}

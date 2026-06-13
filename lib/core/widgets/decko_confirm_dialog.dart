import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../constants/decko_spacing.dart';

/// A polished, on-brand confirmation dialog — Decko's replacement for the stock
/// Material `AlertDialog`. Rounded surface, an icon medallion, and the app's
/// full-width button styling. Returns true when confirmed.
abstract final class DeckoConfirmDialog {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    FaIconData icon = FontAwesomeIcons.circleQuestion,
    bool destructive = false,
  }) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final ColorScheme scheme = theme.colorScheme;
        final Color accent = destructive ? scheme.error : scheme.primary;
        final Color accentBg =
            destructive ? scheme.errorContainer : scheme.primaryContainer;
        final Color onAccentBg =
            destructive ? scheme.onErrorContainer : scheme.onPrimaryContainer;

        return Dialog(
          backgroundColor: scheme.surface,
          insetPadding: const EdgeInsets.all(DeckoSpacing.xl),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DeckoRadii.lg),
          ),
          child: Padding(
            padding: const EdgeInsets.all(DeckoSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  height: 56,
                  width: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accentBg,
                    borderRadius: BorderRadius.circular(DeckoRadii.md),
                  ),
                  child: FaIcon(icon, color: onAccentBg, size: 24),
                ),
                const SizedBox(height: DeckoSpacing.lg),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: DeckoSpacing.sm),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: DeckoSpacing.xl),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(backgroundColor: accent),
                  child: Text(confirmLabel),
                ),
                const SizedBox(height: DeckoSpacing.sm),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(cancelLabel),
                ),
              ],
            ),
          ),
        );
      },
    );
    return ok ?? false;
  }
}

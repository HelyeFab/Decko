import 'package:flutter/material.dart';

import '../constants/decko_spacing.dart';

/// Reusable, branded notifications for Decko.
///
/// Use these instead of raw `SnackBar`s so confirmations look consistent across
/// the app: a floating, rounded pill with an icon. Shown on the app-level
/// `ScaffoldMessenger`, so it survives navigation (e.g. import → library).
abstract final class DeckoSnackbar {
  static void showSuccess(BuildContext context, String message) => _show(
        context,
        message: message,
        icon: Icons.check_circle_rounded,
      );

  static void showInfo(BuildContext context, String message) => _show(
        context,
        message: message,
        icon: Icons.info_rounded,
      );

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: scheme.inverseSurface,
          duration: const Duration(milliseconds: 2200),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DeckoRadii.md),
          ),
          content: Row(
            children: <Widget>[
              Icon(icon, color: scheme.inversePrimary, size: 20),
              const SizedBox(width: DeckoSpacing.md),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: scheme.onInverseSurface),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

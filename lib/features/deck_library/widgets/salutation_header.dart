import 'package:flutter/material.dart';

import '../../../app/decko_app.dart';
import '../../../core/constants/decko_spacing.dart';
import '../../../domain/auth/auth_state.dart';
import '../../../domain/auth/decko_user.dart';

/// A warm, personal greeting at the top of Home (MVP_020.1): a time-based
/// salutation + the signed-in user's first name, with their Google photo when
/// available (initial / placeholder fallback otherwise).
class SalutationHeader extends StatelessWidget {
  const SalutationHeader({super.key, this.now});

  /// Injectable for deterministic tests.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final authRepo = DeckoApp.authOf(context);

    return StreamBuilder<AuthState>(
      stream: authRepo.authStateChanges(),
      initialData: AuthState(authRepo.currentUser),
      builder: (BuildContext context, AsyncSnapshot<AuthState> snap) {
        final DeckoUser? user = snap.data?.user;
        final String greeting = _greeting(now ?? DateTime.now());
        final String name = user?.greetingName ?? 'there';
        return Padding(
          padding: const EdgeInsets.only(bottom: DeckoSpacing.lg),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(greeting,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DeckoSpacing.md),
              _Avatar(user: user),
            ],
          ),
        );
      },
    );
  }

  String _greeting(DateTime now) {
    final int h = now.hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});
  final DeckoUser? user;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String? photo = user?.photoUrl;
    final Widget avatar = (photo != null && photo.isNotEmpty)
        ? CircleAvatar(
            radius: 22,
            backgroundColor: scheme.primaryContainer,
            backgroundImage: NetworkImage(photo),
          )
        : CircleAvatar(
            radius: 22,
            backgroundColor: scheme.primaryContainer,
            child: Text(
              user?.initial ?? '?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          );
    // A theme-compatible ring: the brand accent + a surface gap so it reads as
    // an intentional border on any theme.
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: scheme.primary, width: 2),
      ),
      child: avatar,
    );
  }
}

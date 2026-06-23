import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../app/decko_app.dart';
import '../../core/constants/decko_spacing.dart';
import '../../core/widgets/decko_app_bar.dart';
import '../../core/widgets/decko_snackbar.dart';
import '../../domain/auth/auth_repository.dart';
import '../../domain/auth/auth_state.dart';
import '../../domain/auth/decko_user.dart';
import '../../domain/sync/sync_status.dart';

/// Account & sync (MVP_020, DEC-029). Sign in to protect XP / streaks / history
/// across devices — Decko stays fully usable local-only, and review scheduling
/// always stays on the device.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Runs an auth action with a busy guard + friendly error surfacing.
  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _afterSignIn() async {
    if (!mounted) return;
    final result = await DeckoApp.syncOf(context).syncNow();
    if (mounted && result.ok) {
      DeckoSnackbar.showSuccess(context, 'Signed in — your progress is syncing.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthRepository auth = DeckoApp.authOf(context);
    return Scaffold(
      appBar: const DeckoAppBar(title: 'Account & sync'),
      body: SafeArea(
        child: StreamBuilder<AuthState>(
          stream: auth.authStateChanges(),
          initialData: AuthState(auth.currentUser),
          builder: (BuildContext context, AsyncSnapshot<AuthState> snap) {
            final AuthState state = snap.data ?? AuthState.localOnly;
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                DeckoSpacing.pagePadding,
                DeckoSpacing.lg,
                DeckoSpacing.pagePadding,
                DeckoSpacing.xxxl,
              ),
              children: state.user == null
                  ? _signedOut(context)
                  : _signedIn(context, state.user!),
            );
          },
        ),
      ),
    );
  }

  // ---- Signed out ---------------------------------------------------------

  List<Widget> _signedOut(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return <Widget>[
      _Hero(
        icon: FontAwesomeIcons.cloudArrowUp,
        title: 'Sync your progress',
        body: 'Sign in to protect your XP, streaks, and history across devices. '
            'Decko works fully without an account.',
      ),
      const SizedBox(height: DeckoSpacing.xl),
      TextField(
        controller: _email,
        enabled: !_busy,
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        decoration: const InputDecoration(
          labelText: 'Email',
          prefixIcon: Icon(Icons.alternate_email, size: 18),
        ),
      ),
      const SizedBox(height: DeckoSpacing.md),
      TextField(
        controller: _password,
        enabled: !_busy,
        obscureText: true,
        decoration: const InputDecoration(
          labelText: 'Password',
          prefixIcon: Icon(Icons.lock_outline, size: 18),
        ),
      ),
      if (_error != null) ...<Widget>[
        const SizedBox(height: DeckoSpacing.md),
        Text(_error!,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.error)),
      ],
      const SizedBox(height: DeckoSpacing.lg),
      FilledButton(
        onPressed: _busy ? null : () => _run(_signInEmail),
        child: _busy
            ? const _Spinner()
            : const Text('Sign in'),
      ),
      const SizedBox(height: DeckoSpacing.sm),
      OutlinedButton(
        onPressed: _busy ? null : () => _run(_createAccount),
        child: const Text('Create account'),
      ),
      const SizedBox(height: DeckoSpacing.lg),
      const _OrDivider(),
      const SizedBox(height: DeckoSpacing.lg),
      OutlinedButton.icon(
        onPressed: _busy ? null : () => _run(_signInGoogle),
        icon: const FaIcon(FontAwesomeIcons.google, size: 16),
        label: const Text('Continue with Google'),
      ),
      const SizedBox(height: DeckoSpacing.lg),
      _Note(
        'Your review schedule, due dates, and imported decks always stay on '
        'this device — signing in never changes them.',
      ),
    ];
  }

  Future<void> _signInEmail() async {
    await DeckoApp.authOf(context)
        .signInWithEmail(_email.text, _password.text);
    await _afterSignIn();
  }

  Future<void> _createAccount() async {
    await DeckoApp.authOf(context)
        .createAccountWithEmail(_email.text, _password.text);
    await _afterSignIn();
  }

  Future<void> _signInGoogle() async {
    await DeckoApp.authOf(context).signInWithGoogle();
    await _afterSignIn();
  }

  // ---- Signed in ----------------------------------------------------------

  List<Widget> _signedIn(BuildContext context, DeckoUser user) {
    return <Widget>[
      _ProfileCard(user: user),
      const SizedBox(height: DeckoSpacing.lg),
      _SyncCard(busy: _busy, onSync: () => _run(_syncNow)),
      const SizedBox(height: DeckoSpacing.lg),
      const _WhatSyncsCard(),
      const SizedBox(height: DeckoSpacing.lg),
      OutlinedButton(
        onPressed: _busy ? null : () => _run(_signOut),
        child: const Text('Sign out'),
      ),
    ];
  }

  Future<void> _syncNow() async {
    final result = await DeckoApp.syncOf(context).syncNow();
    if (!mounted) return;
    if (result.ok) {
      DeckoSnackbar.showSuccess(context,
          'Synced — ${result.uploaded} events backed up.');
    } else {
      setState(() => _error = result.error);
    }
  }

  Future<void> _signOut() async {
    await DeckoApp.authOf(context).signOut();
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.icon, required this.title, required this.body});
  final FaIconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(DeckoSpacing.xl),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(DeckoRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FaIcon(icon, size: 28, color: scheme.onPrimaryContainer),
          const SizedBox(height: DeckoSpacing.md),
          Text(title,
              style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onPrimaryContainer)),
          const SizedBox(height: DeckoSpacing.xs),
          Text(body,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onPrimaryContainer)),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});
  final DeckoUser user;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String title =
        user.isAnonymous ? 'Anonymous account' : (user.email ?? 'Signed in');
    final String subtitle = user.isAnonymous
        ? 'A private cloud identity on this device'
        : 'Signed in';
    return _Surface(
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 26,
            backgroundColor: scheme.primaryContainer,
            child: FaIcon(
              user.isAnonymous
                  ? FontAwesomeIcons.userSecret
                  : FontAwesomeIcons.solidUser,
              size: 20,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: DeckoSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(subtitle,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncCard extends StatelessWidget {
  const _SyncCard({required this.busy, required this.onSync});
  final bool busy;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return _Surface(
      child: StreamBuilder<SyncState>(
        stream: DeckoApp.syncOf(context).syncStateChanges(),
        initialData: DeckoApp.syncOf(context).current,
        builder: (BuildContext context, AsyncSnapshot<SyncState> snap) {
          final SyncState state = snap.data ?? SyncState.idle;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  FaIcon(_icon(state.status),
                      size: 16, color: scheme.primary),
                  const SizedBox(width: DeckoSpacing.sm),
                  Text('Cloud sync',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: DeckoSpacing.xs),
              Text(_label(state),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: DeckoSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: (busy || state.status == SyncStatus.syncing)
                      ? null
                      : onSync,
                  child: state.status == SyncStatus.syncing
                      ? const _Spinner()
                      : const Text('Sync now'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  FaIconData _icon(SyncStatus s) => switch (s) {
        SyncStatus.synced => FontAwesomeIcons.solidCircleCheck,
        SyncStatus.syncing => FontAwesomeIcons.arrowsRotate,
        SyncStatus.failed => FontAwesomeIcons.triangleExclamation,
        SyncStatus.offline => FontAwesomeIcons.cloudArrowUp,
        SyncStatus.idle => FontAwesomeIcons.cloud,
      };

  String _label(SyncState s) {
    switch (s.status) {
      case SyncStatus.syncing:
        return 'Syncing your progress…';
      case SyncStatus.synced:
        return s.lastSyncedAt == null
            ? 'Up to date.'
            : 'Up to date · last synced ${_time(s.lastSyncedAt!)}.';
      case SyncStatus.failed:
        return s.message ?? 'Sync failed — your progress is safe locally.';
      case SyncStatus.offline:
        return 'Offline — Decko will sync when you’re back online.';
      case SyncStatus.idle:
        return 'Not synced yet. Tap “Sync now” to back up your progress.';
    }
  }

  String _time(DateTime t) {
    final String hh = t.hour.toString().padLeft(2, '0');
    final String mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

class _WhatSyncsCard extends StatelessWidget {
  const _WhatSyncsCard();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    Widget line(FaIconData icon, Color color, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              FaIcon(icon, size: 13, color: color),
              const SizedBox(width: DeckoSpacing.sm),
              Expanded(
                  child: Text(text, style: theme.textTheme.bodySmall)),
            ],
          ),
        );
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('What syncs',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: DeckoSpacing.sm),
          line(FontAwesomeIcons.check, scheme.primary,
              'XP, streaks, achievements, and activity history'),
          line(FontAwesomeIcons.check, scheme.primary,
              'App settings — theme, furigana, daily goal'),
          const SizedBox(height: DeckoSpacing.sm),
          line(FontAwesomeIcons.lock, scheme.onSurfaceVariant,
              'Stays on this device: your decks, media, review schedule, and '
              'due dates'),
        ],
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});
  final Widget child;

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
      child: child,
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Text(text,
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant));
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        Expanded(child: Divider(color: scheme.outlineVariant)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DeckoSpacing.md),
          child: Text('or',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
        ),
        Expanded(child: Divider(color: scheme.outlineVariant)),
      ],
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();
  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
}

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../app/decko_app.dart';
import '../../../core/constants/decko_spacing.dart';
import '../../../core/widgets/decko_confirm_dialog.dart';
import '../../../core/widgets/decko_snackbar.dart';
import '../../../data/sync/review_state_sync_service.dart';
import '../../../domain/deck.dart';
import '../../../domain/sync/deck_sync_status.dart';

/// Deck-detail cross-device sync status (MVP_022/023). Shows the deck's plain-
/// language sync state and, when cloud progress is available, an explicit (never
/// automatic) "Apply synced progress" flow with a clear confirmation. Renders
/// nothing when signed out / Firebase off / the deck has no stable identity.
class ReviewSyncBanner extends StatefulWidget {
  const ReviewSyncBanner({
    super.key,
    required this.deck,
    required this.onApplied,
  });

  final Deck deck;
  final VoidCallback onApplied;

  @override
  State<ReviewSyncBanner> createState() => _ReviewSyncBannerState();
}

class _ReviewSyncBannerState extends State<ReviewSyncBanner> {
  ReviewStateSyncService? _sync;
  Future<DeckSyncStatus>? _future;
  bool _applying = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync ??= DeckoApp.reviewSyncOf(context);
    _future ??= _sync?.deckStatus(widget.deck);
  }

  Future<void> _confirmAndApply(DeckSyncStatus status) async {
    final bool ok = await DeckoConfirmDialog.show(
      context,
      icon: FontAwesomeIcons.cloudArrowDown,
      title: 'Apply synced progress?',
      message:
          'Decko found review progress for ${status.cloudAheadCount} '
          'card${status.cloudAheadCount == 1 ? '' : 's'} from another device, '
          'matching ${status.localCardsMatched} of your local cards.\n\n'
          'This updates review state for matching cards only — never your deck '
          'content, media, or card text. Local progress that is newer or safer '
          'will not be overwritten.',
      confirmLabel: 'Apply',
    );
    if (!ok || !mounted) return;

    final ReviewStateSyncService? sync = _sync;
    if (sync == null) return;
    setState(() => _applying = true);
    final ReviewApplyResult result = await sync.applyToDeck(widget.deck);
    if (!mounted) return;
    setState(() {
      _applying = false;
      _future = sync.deckStatus(widget.deck);
    });
    widget.onApplied();
    final String kept =
        result.conflicts > 0 ? ' · ${result.conflicts} kept local' : '';
    DeckoSnackbar.showSuccess(
        context, 'Applied progress to ${result.applied} cards$kept.');
  }

  @override
  Widget build(BuildContext context) {
    if (_sync == null || _future == null) return const SizedBox.shrink();
    return FutureBuilder<DeckSyncStatus>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<DeckSyncStatus> snap) {
        final DeckSyncStatus? s = snap.data;
        if (s == null) return const SizedBox.shrink();
        switch (s.state) {
          case DeckSyncState.cloudAhead:
            return _ApplyBanner(
              status: s,
              applying: _applying,
              onApply: () => _confirmAndApply(s),
            );
          case DeckSyncState.matchedUpToDate:
            return const _Pill(
                icon: FontAwesomeIcons.solidCircleCheck,
                text: 'Review progress synced',
                tone: _Tone.good);
          case DeckSyncState.localAhead:
            return const _Pill(
                icon: FontAwesomeIcons.cloudArrowUp,
                text: 'Local progress is newer than the cloud',
                tone: _Tone.muted);
          case DeckSyncState.conflict:
            return const _Pill(
                icon: FontAwesomeIcons.shield,
                text: 'Decko kept your local progress',
                tone: _Tone.muted);
          case DeckSyncState.notMatched:
            return const _Pill(
                icon: FontAwesomeIcons.cloud,
                text: 'Not matched yet — import this deck on another device to '
                    'sync review progress',
                tone: _Tone.muted);
          case DeckSyncState.offline:
            return const _Pill(
                icon: FontAwesomeIcons.cloudArrowUp,
                text: 'Offline — studying still works; Decko will sync later',
                tone: _Tone.muted);
          case DeckSyncState.signedOut:
          case DeckSyncState.notImportedDeck:
            return const SizedBox.shrink();
        }
      },
    );
  }
}

class _ApplyBanner extends StatelessWidget {
  const _ApplyBanner({
    required this.status,
    required this.applying,
    required this.onApply,
  });
  final DeckSyncStatus status;
  final bool applying;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: DeckoSpacing.lg),
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
              FaIcon(FontAwesomeIcons.cloudArrowDown,
                  size: 18, color: scheme.onPrimaryContainer),
              const SizedBox(width: DeckoSpacing.sm),
              Text('Synced progress available',
                  style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onPrimaryContainer)),
            ],
          ),
          const SizedBox(height: DeckoSpacing.xs),
          Text(
            'This looks like a deck you studied on another device — review '
            'progress for ${status.cloudAheadCount} '
            'card${status.cloudAheadCount == 1 ? '' : 's'} can be applied here.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: DeckoSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: applying ? null : onApply,
              child: applying
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Apply synced progress'),
            ),
          ),
        ],
      ),
    );
  }
}

enum _Tone { good, muted }

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text, required this.tone});
  final FaIconData icon;
  final String text;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color color =
        tone == _Tone.good ? scheme.primary : scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: DeckoSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: FaIcon(icon, size: 13, color: color),
          ),
          const SizedBox(width: DeckoSpacing.sm),
          Expanded(
            child: Text(text,
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}

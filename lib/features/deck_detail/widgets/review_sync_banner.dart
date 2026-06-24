import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../app/decko_app.dart';
import '../../../core/constants/decko_spacing.dart';
import '../../../core/widgets/decko_snackbar.dart';
import '../../../data/sync/review_state_sync_service.dart';
import '../../../domain/deck.dart';

/// Surfaces cross-device review-state sync on deck detail (MVP_022): "synced
/// progress available → Apply" (explicit, never automatic), or a quiet "synced"
/// indicator. Renders nothing when Firebase is off, the user is signed out, or
/// the deck has no stable identity.
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
  Future<ReviewSyncAvailability>? _future;
  bool _applying = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync ??= DeckoApp.reviewSyncOf(context);
    _future ??= _sync?.availableFor(widget.deck);
  }

  Future<void> _apply() async {
    final ReviewStateSyncService? sync = _sync;
    if (sync == null) return;
    setState(() => _applying = true);
    final ReviewApplyResult result = await sync.applyToDeck(widget.deck);
    if (!mounted) return;
    setState(() {
      _applying = false;
      _future = sync.availableFor(widget.deck); // refresh → now "synced"
    });
    widget.onApplied();
    final String conflicts = result.conflicts > 0
        ? ' (${result.conflicts} kept local)'
        : '';
    DeckoSnackbar.showSuccess(
        context, 'Applied synced progress to ${result.applied} cards$conflicts.');
  }

  @override
  Widget build(BuildContext context) {
    if (_sync == null || _future == null) return const SizedBox.shrink();
    return FutureBuilder<ReviewSyncAvailability>(
      future: _future,
      builder: (BuildContext context,
          AsyncSnapshot<ReviewSyncAvailability> snap) {
        final ReviewSyncAvailability? a = snap.data;
        if (a == null || !a.fingerprintable) return const SizedBox.shrink();
        if (a.progressAvailable) {
          return _AvailableBanner(
            count: a.applicableCount,
            applying: _applying,
            onApply: _apply,
          );
        }
        if (a.hasCloudProgress) return const _SyncedPill();
        return const SizedBox.shrink();
      },
    );
  }
}

class _AvailableBanner extends StatelessWidget {
  const _AvailableBanner({
    required this.count,
    required this.applying,
    required this.onApply,
  });
  final int count;
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
            'Review progress for $count card${count == 1 ? '' : 's'} from '
            'another device. Your local cards are never overwritten with older '
            'progress.',
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

class _SyncedPill extends StatelessWidget {
  const _SyncedPill();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: DeckoSpacing.lg),
      child: Row(
        children: <Widget>[
          FaIcon(FontAwesomeIcons.solidCircleCheck,
              size: 13, color: scheme.primary),
          const SizedBox(width: DeckoSpacing.sm),
          Text('Review progress synced',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

import 'package:flutter/widgets.dart';

import '../../app/decko_app.dart';
import '../../domain/activity/activity_event.dart';
import '../../domain/practice/practice_outcome.dart';

/// Builds an `onCompleted` sink that records a practice [PracticeOutcome] to
/// both motivational progress and the activity ledger (MVP_019). Capturing the
/// repositories now keeps it safe to call after the game's async gaps.
void Function(PracticeOutcome) practiceOutcomeSink(BuildContext context) {
  final recordSnapshot = DeckoApp.progressOf(context).recordPracticeOutcome;
  final ledger = DeckoApp.ledgerOf(context);
  return (PracticeOutcome outcome) {
    recordSnapshot(outcome);
    ledger.record(ActivityEvent.practice(outcome));
  };
}

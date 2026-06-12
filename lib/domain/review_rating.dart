/// How a learner rated a card after seeing the answer.
///
/// These four ratings mirror the grades an FSRS-style scheduler expects, so the
/// review UI can be built now and wired to a real `SchedulerService` later
/// without changing the rating vocabulary (see DEC-003).
enum ReviewRating {
  again,
  hard,
  good,
  easy;

  /// User-facing label (British English copy).
  String get label => switch (this) {
        ReviewRating.again => 'Again',
        ReviewRating.hard => 'Hard',
        ReviewRating.good => 'Good',
        ReviewRating.easy => 'Easy',
      };

  /// Short hint shown under the rating button.
  String get hint => switch (this) {
        ReviewRating.again => 'Forgot it',
        ReviewRating.hard => 'Tricky',
        ReviewRating.good => 'Got it',
        ReviewRating.easy => 'Too easy',
      };
}

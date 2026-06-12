import 'review_rating.dart';

/// A single graded answer recorded during a review session.
///
/// Framework-light: no Flutter imports. [answeredAt] is supplied by the caller
/// (not read from the clock here) so sessions stay deterministic and testable.
class ReviewAnswer {
  const ReviewAnswer({
    required this.itemId,
    required this.rating,
    required this.answeredAt,
  });

  final String itemId;
  final ReviewRating rating;
  final DateTime answeredAt;
}

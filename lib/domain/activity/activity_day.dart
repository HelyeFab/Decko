/// One calendar day's worth of activity, for the heatmap (MVP_019).
/// Framework-light.
class ActivityDay {
  const ActivityDay({
    required this.day,
    this.xp = 0,
    this.reviewCount = 0,
    this.practiceCount = 0,
    this.totalEvents = 0,
  });

  /// Local calendar day (date-only, time at midnight).
  final DateTime day;
  final int xp;
  final int reviewCount;
  final int practiceCount;
  final int totalEvents;

  bool get isEmpty => totalEvents == 0;
}

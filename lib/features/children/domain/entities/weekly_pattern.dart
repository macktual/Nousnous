import 'schedule.dart';

class WeeklyPattern {
  const WeeklyPattern({
    required this.id,
    required this.childId,
    required this.name,
    required this.isActive,
    required this.entries,
    this.validFrom,
    this.validUntil,
  });

  final int id;
  final int childId;
  final String name; // ex. 'Semaine A', 'Semaine B'
  final bool isActive;
  final List<ScheduleEntry> entries;
  /// Date à compter de laquelle ces horaires s'appliquent (null = horaires initiaux).
  final DateTime? validFrom;
  /// Date jusqu'à laquelle ces horaires s'appliquaient (null = toujours en vigueur).
  final DateTime? validUntil;
}


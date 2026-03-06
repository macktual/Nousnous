class ScheduleEntry {
  const ScheduleEntry({
    required this.id,
    required this.patternId,
    required this.weekday,
    required this.arrivalTime,
    required this.departureTime,
  });

  final int id;
  final int patternId;
  final int weekday; // 1 = lundi ... 5 = vendredi
  final String? arrivalTime; // 'HH:mm'
  final String? departureTime; // 'HH:mm'
}


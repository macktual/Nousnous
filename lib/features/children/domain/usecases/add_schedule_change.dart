import '../entities/weekly_pattern.dart';
import '../repositories/child_repository.dart';

class AddScheduleChange {
  const AddScheduleChange(this._repository);

  final ChildRepository _repository;

  Future<void> call(int childId, DateTime validFromDate, List<WeeklyPattern> newPatterns) {
    return _repository.addScheduleChange(childId, validFromDate, newPatterns);
  }
}

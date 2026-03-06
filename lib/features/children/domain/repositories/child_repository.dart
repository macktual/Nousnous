import '../entities/child.dart';
import '../entities/weekly_pattern.dart';

abstract class ChildRepository {
  Future<List<Child>> getActiveChildren();
  Future<List<Child>> getArchivedChildren();
  Future<Child?> getChildById(int id);
  Future<int> createChild(Child child);
  Future<void> updateChild(Child child);
  /// Enregistre de nouveaux horaires à compter de [validFromDate] en conservant l'historique.
  Future<void> addScheduleChange(int childId, DateTime validFromDate, List<WeeklyPattern> newPatterns);
  Future<void> archiveChild(int id, {DateTime? contractEndDate, String? particularitesFinContrat, String? archiveSignaturePath});
  Future<void> deleteArchivedChild(int id);
}


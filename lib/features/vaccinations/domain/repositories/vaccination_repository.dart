import '../entities/vaccination_entry.dart';
import '../entities/vaccination_rule.dart';

abstract class VaccinationRepository {
  Future<List<VaccinationEntry>> getScheduleForChild(int childId, DateTime birthDate, {String? vaccinationScheme});
  Future<void> setVaccinationDone(int childId, int ruleId, {DateTime? actualDate});
  Future<void> setVaccinationUndone(int childId, int ruleId);
  /// Met à jour le justificatif (source + date et/ou photo) pour une vaccination déjà effectuée.
  Future<void> setJustification(
    int childId,
    int ruleId, {
    String? justificationSource,
    DateTime? justificationDate,
    String? justificationPhotoPath,
  });
  Future<List<VaccinationRule>> getAllRules();
  Future<void> updateRule(VaccinationRule rule);
  Future<void> insertRule(VaccinationRule rule);
  Future<void> deleteRule(int ruleId);
}

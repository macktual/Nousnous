import '../repositories/vaccination_repository.dart';

class UpdateVaccinationStatus {
  const UpdateVaccinationStatus(this._repo);

  final VaccinationRepository _repo;

  Future<void> setDone(int childId, int ruleId, {DateTime? actualDate}) {
    return _repo.setVaccinationDone(childId, ruleId, actualDate: actualDate);
  }

  Future<void> setUndone(int childId, int ruleId) {
    return _repo.setVaccinationUndone(childId, ruleId);
  }

  Future<void> setJustification(
    int childId,
    int ruleId, {
    String? justificationSource,
    DateTime? justificationDate,
    String? justificationPhotoPath,
  }) {
    return _repo.setJustification(
      childId,
      ruleId,
      justificationSource: justificationSource,
      justificationDate: justificationDate,
      justificationPhotoPath: justificationPhotoPath,
    );
  }
}

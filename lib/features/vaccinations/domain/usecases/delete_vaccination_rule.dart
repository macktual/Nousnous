import '../repositories/vaccination_repository.dart';

class DeleteVaccinationRule {
  const DeleteVaccinationRule(this._repo);

  final VaccinationRepository _repo;

  Future<void> call(int ruleId) {
    return _repo.deleteRule(ruleId);
  }
}

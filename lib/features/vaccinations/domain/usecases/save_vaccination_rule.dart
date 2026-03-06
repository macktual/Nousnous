import '../entities/vaccination_rule.dart';
import '../repositories/vaccination_repository.dart';

class SaveVaccinationRule {
  const SaveVaccinationRule(this._repo);

  final VaccinationRepository _repo;

  Future<void> insert(VaccinationRule rule) {
    return _repo.insertRule(rule);
  }

  Future<void> update(VaccinationRule rule) {
    return _repo.updateRule(rule);
  }
}

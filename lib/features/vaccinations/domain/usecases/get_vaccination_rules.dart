import '../entities/vaccination_rule.dart';
import '../repositories/vaccination_repository.dart';

class GetVaccinationRules {
  const GetVaccinationRules(this._repo);

  final VaccinationRepository _repo;

  Future<List<VaccinationRule>> call() {
    return _repo.getAllRules();
  }
}

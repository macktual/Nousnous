import '../entities/vaccination_entry.dart';
import '../repositories/vaccination_repository.dart';

class GetVaccinationSchedule {
  const GetVaccinationSchedule(this._repo);

  final VaccinationRepository _repo;

  Future<List<VaccinationEntry>> call(int childId, DateTime birthDate, {String? vaccinationScheme}) {
    return _repo.getScheduleForChild(childId, birthDate, vaccinationScheme: vaccinationScheme);
  }
}

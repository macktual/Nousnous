import '../repositories/medication_repository.dart';

class GetMedicationNames {
  const GetMedicationNames(this._repo);

  final MedicationRepository _repo;

  Future<List<String>> call() {
    return _repo.getMedicationNames();
  }
}


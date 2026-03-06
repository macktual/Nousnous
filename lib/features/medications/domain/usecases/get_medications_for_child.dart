import '../entities/medication_entry.dart';
import '../repositories/medication_repository.dart';

class GetMedicationsForChild {
  const GetMedicationsForChild(this._repo);

  final MedicationRepository _repo;

  Future<List<MedicationEntry>> call(int childId) {
    return _repo.getForChild(childId);
  }
}

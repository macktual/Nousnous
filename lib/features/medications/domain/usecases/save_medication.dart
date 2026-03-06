import '../entities/medication_entry.dart';
import '../repositories/medication_repository.dart';

class SaveMedication {
  const SaveMedication(this._repo);

  final MedicationRepository _repo;

  Future<MedicationEntry> call(MedicationEntry entry) {
    if (entry.id == 0) {
      return _repo.insert(entry);
    }
    return _repo.update(entry).then((_) => entry);
  }
}

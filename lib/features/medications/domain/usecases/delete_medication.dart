import '../repositories/medication_repository.dart';

class DeleteMedication {
  const DeleteMedication(this._repo);

  final MedicationRepository _repo;

  Future<void> call(int id) {
    return _repo.delete(id);
  }
}

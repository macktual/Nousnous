import '../entities/doliprane_prescription.dart';
import '../repositories/doliprane_repository.dart';

class SaveDolipranePrescription {
  const SaveDolipranePrescription(this._repo);

  final DolipraneRepository _repo;

  Future<DolipranePrescription> call(DolipranePrescription prescription) {
    if (prescription.id == 0) {
      return _repo.insert(prescription);
    }
    return _repo.update(prescription).then((_) => prescription);
  }
}

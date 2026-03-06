import '../entities/disease_entry.dart';
import '../repositories/disease_repository.dart';

class SaveDisease {
  const SaveDisease(this._repo);

  final DiseaseRepository _repo;

  Future<DiseaseEntry> call(DiseaseEntry entry) {
    if (entry.id == 0) {
      return _repo.insert(entry);
    }
    return _repo.update(entry).then((_) => entry);
  }
}

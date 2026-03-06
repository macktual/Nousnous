import '../entities/disease_entry.dart';
import '../repositories/disease_repository.dart';

class GetDiseasesForChild {
  const GetDiseasesForChild(this._repo);

  final DiseaseRepository _repo;

  Future<List<DiseaseEntry>> call(int childId) {
    return _repo.getForChild(childId);
  }
}

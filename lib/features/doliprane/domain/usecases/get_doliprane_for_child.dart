import '../entities/doliprane_prescription.dart';
import '../repositories/doliprane_repository.dart';

class GetDolipraneForChild {
  const GetDolipraneForChild(this._repo);

  final DolipraneRepository _repo;

  Future<List<DolipranePrescription>> call(int childId) {
    return _repo.getForChild(childId);
  }
}
